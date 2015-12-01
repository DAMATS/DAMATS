#-------------------------------------------------------------------------------
#
#  DAMATS web app Django views - time series operations
#
# Project: EOxServer <http://eoxserver.org>
# Authors: Martin Paces <martin.paces@eox.at>
#
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies of this Software or works derived from this Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-------------------------------------------------------------------------------
# pylint: disable=missing-docstring,unused-argument

import json
import uuid
from datetime import datetime

#from django.conf import settings
#from django.http import HttpResponse
from django.db import transaction
from django.db.models import Q
from django.core.exceptions import ObjectDoesNotExist
from django.contrib.gis.geos import Polygon

from eoxserver.core.util.timetools import isoformat
from eoxserver.resources.coverages.models import DatasetSeries, Coverage

from damats.webapp.models import SourceSeries, TimeSeries
from damats.util.object_parser import (
    Object, String, Float, DateTime, Bool, Null,
)
from damats.util.view_utils import (
    HttpError, error_handler, method_allow, method_allow_conditional,
    rest_json,
)
from damats.webapp.views_common import authorisation, JSON_OPTS

TOLERANCE = 0.0

#-------------------------------------------------------------------------------

def pack_datetime(obj):
    if isinstance(obj, datetime):
        return "%sZ" % obj.isoformat('T')
    elif not isinstance(obj, dict):
        return obj
    else:
        return dict((key, pack_datetime(val)) for key, val in obj.iteritems())

SELECTION_PARSER = Object((
    ('aoi', Object((
        ('left', Float, True),
        ('right', Float, True),
        ('bottom', Float, True),
        ('top', Float, True),
    ))),
    ('toi', Object((
        ('start', DateTime, True),
        ('end', DateTime, True),
    ))),
))

SITS_PARSER = Object((
    ('source', String, True),
    ('locked', Bool, False, False),
    ('name', (String, Null), False, None),
    ('description', (String, Null), False, None),
    ('selection', Object((
        ('aoi', Object((
            ('left', Float, True),
            ('right', Float, True),
            ('bottom', Float, True),
            ('top', Float, True),
        )), True),
        ('toi', Object((
            ('start', DateTime, True),
            ('end', DateTime, True),
        )), True),
    )), True),
))

COVERAGE_PARSER = Object((
    ('identifier', String),
))

#-------------------------------------------------------------------------------
# quaries

def get_sources(user):
    """ Get a query set of all SourceSeries objects accessible by the user. """
    id_list = [user.identifier] + [obj.identifier for obj in user.groups.all()]
    return (
        SourceSeries.objects
        .select_related('eoobj')
        .filter(readers__identifier__in=id_list)
    )

def get_time_series(user, owned=True, read_only=True):
    """ Get a query set of TimeSeries objects accessible by the user.
        By default both owned and read-only (items shared by a different users)
        are returned.
    """
    id_list = [user.identifier] + [obj.identifier for obj in user.groups.all()]
    qset = TimeSeries.objects.select_related(
        'eoobj', 'owner', 'source', 'source__eoobj',
    )
    if owned and read_only:
        qset = qset.filter(Q(owner=user) | Q(readers__identifier__in=id_list))
    elif owned:
        qset = qset.filter(owner=user)
    elif read_only:
        qset = qset.filter(readers__identifier__in=id_list)
    else: #nothing selected
        return []
    return qset

def is_time_series_owned(request, user, identifier, *args, **kwargs):
    """ Return true if the time_series object is owned by the user. """
    try:
        obj = get_time_series(user).get(eoobj__identifier=identifier)
    except ObjectDoesNotExist:
        raise HttpError(404, "Not found")
    return obj.owner == user

def get_collection(identifier):
    """ Get an existing DatastSeries database object for given identifier. """
    try:
        return DatasetSeries.objects.get(identifier=identifier)
    except ObjectDoesNotExist:
        raise ValueError("Invalid EOObject identifier %r!" % identifier)

def get_coverages(eoobj):
    """ Get a query set of all Coverages held by given DatastSeries object.
    """
    def _get_children_ids(eoobj):
        """ recursive dataset series lookup """
        qset = (
            eoobj.cast().eo_objects
            .filter(real_content_type=eoobj.real_content_type)
        )
        id_list = [eoobj.id]
        for child_eoobj in qset:
            id_list.extend(_get_children_ids(child_eoobj))
        return id_list

    return Coverage.objects.filter(collections__id__in=_get_children_ids(eoobj))

#-------------------------------------------------------------------------------
# model instance serialization

def source_serialize(obj, extras=None):
    """ Serialize SourceSeries django model instance to a JSON serializable
        dictionary.
    """
    response = extras if extras else {}
    response.update({
        "identifier": obj.eoobj.identifier,
        "name": obj.name or None,
        "description": obj.description or None,
    })
    return response

def time_series_serialize(obj, user, extras=None):
    """ Serialize TimeSeries django model instance to a JSON serializable
        dictionary.
    """
    response = extras if extras else {}
    response.update({
        "identifier": obj.eoobj.identifier,
        "source": obj.source.eoobj.identifier,
        "name": obj.name or None,
        "description": obj.description or None,
        "locked": obj.locked or obj.owner != user,
        "owned": obj.owner == user,
        "selection": json.loads(obj.selection or '{}'),
    })
    return response

COVERAGE_KEYS = ('id', 't0', 't1', 'x0', 'x1', 'y0', 'y1')
def coverage_serialize(obj):
    """ Serialize Coverage object to a JSON serializable dictionary """
    lon_min, lat_min, lon_max, lat_max = obj.extent_wgs84
    return dict(zip(COVERAGE_KEYS, (
        obj.identifier, isoformat(obj.begin_time), isoformat(obj.end_time),
        lon_min, lon_max, lat_min, lat_max,
    )))

def coverage_serialize_extra(obj, extra):
    """ Serialize Coverage object to a JSON serializable dictionary """
    tmp = coverage_serialize(obj)
    tmp.update(extra)
    return tmp
#-------------------------------------------------------------------------------
# object creation

def create_collection(identifier):
    """ Create new DatasetSeries with the given identier. """
    obj = DatasetSeries(identifier=identifier)
    obj.save()
    return obj

@transaction.atomic
def create_time_series(input_, user):
    """ Handle create requests and create a new TimeSeries object. """

    def pack_selection(selection):
        """ pack selection object """

    # First check the source.
    try:
        source = get_sources(user).get(
            eoobj__identifier=input_.get('source', None)
        )
    except ObjectDoesNotExist:
        raise HttpError(400, "Bad Request")

    # Create a new object.
    obj = TimeSeries()
    obj.owner = user
    locked = input_.get("locked", False)
    obj.locked = locked if locked is not None else False
    obj.name = input_.get('name', None) or None
    obj.description = input_.get('description', None) or None
    obj.source = source
    obj.eoobj = target = create_collection("sits-" + uuid.uuid4().hex)
    obj.selection = json.dumps(
        pack_datetime(input_.get('selection', {}) or {})
    )
    obj.save()

    # link matching coverages
    # TODO: dateline handling
    # TODO: tune the tolerance

    aoi = input_['selection']['aoi']
    toi = input_['selection']['toi']

    bbox = (
        aoi['left'] - TOLERANCE,
        aoi['bottom'] - TOLERANCE,
        aoi['right'] + TOLERANCE,
        aoi['top'] + TOLERANCE,
    )
    bbox_geom = Polygon.from_bbox(bbox)

    coverages = get_coverages(source.eoobj).filter(
        begin_time__lte=toi['end'], end_time__gte=toi['start'],
        footprint__intersects=bbox_geom,
        #footprint__within=bbox_geom,
    )
    for eoobj in coverages:
        target.insert(eoobj)

    return 200, time_series_serialize(obj, user)

#-------------------------------------------------------------------------------
# views

@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS)
def sources_view(method, input_, user, **kwargs):
    """ List avaiable source time series.
    """
    return 200, [source_serialize(obj) for obj in get_sources(user)]

@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS)
def sources_item_view(method, input_, user, identifier, **kwargs):
    """ List items of the requested source time series.
    """
    try:
        obj = get_sources(user).get(eoobj__identifier=identifier)
    except ObjectDoesNotExist:
        raise HttpError(404, "Not found")

    return 200, [
        coverage_serialize(cov)
        for cov in get_coverages(obj.eoobj).order_by('begin_time', 'end_time')
    ]

@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS)
def sources_coverage_view(method, input_, user, identifier, coverage, **kwargs):
    """ View a requested item of the source time series.
    """
    try:
        obj = get_sources(user).get(eoobj__identifier=identifier)
        cov = get_coverages(obj.eoobj).get(identifier=coverage)
    except ObjectDoesNotExist:
        raise HttpError(404, "Not found")

    return 200, coverage_serialize(cov)

@error_handler
@authorisation
@method_allow(['GET', 'POST'])
@rest_json(JSON_OPTS, SITS_PARSER)
def time_series_view(method, input_, user, **kwargs):
    """ List avaiable time-series.
    """
    if method == "POST": # new object to be created
        return create_time_series(input_, user)

    # otherwise list existing objects
    return 200, [
        time_series_serialize(obj, user)
        for obj in get_time_series(user).order_by('created')
    ]

@error_handler
@authorisation
@method_allow_conditional(['GET', 'POST', 'DELETE'], ['GET'], is_time_series_owned)
@rest_json(JSON_OPTS, COVERAGE_PARSER)
def time_series_item_view(method, input_, user, identifier, **kwargs):
    """ List items of the requested time series.
    """
    try:
        obj = get_time_series(user).get(eoobj__identifier=identifier)
    except ObjectDoesNotExist:
        raise HttpError(404, "Not found")

    if method == "DELETE":
        eoobj = obj.eoobj
        with transaction.atomic():
            obj.delete()
            eoobj.delete()
        return 204, None

    elif method == "POST":
        coverage = input_['identifier']
        try:
            cov = get_coverages(obj.source.eoobj).get(identifier=coverage)
        except ObjectDoesNotExist:
            raise HttpError(400, "Bad Request")
        obj.eoobj.insert(cov)
        return 200, coverage_serialize(cov)

    if 'all' not in kwargs['request'].GET:
        # list only coverages inluded in the collection
        return 200, [
            coverage_serialize(cov) for cov
            in get_coverages(obj.eoobj).order_by('begin_time', 'end_time')
        ]
    else:
        # list all avaiilable coverages mathing the selection

        included = set()
        for cov in get_coverages(obj.eoobj):
            included.add(cov.identifier)

        # list avaiable
        selection = SELECTION_PARSER.parse(json.loads(obj.selection or '{}'))
        toi = selection.get('toi', None)
        aoi = selection.get('aoi', None)

        coverages = get_coverages(obj.source.eoobj)
        if toi:
            coverages = coverages.filter(
                begin_time__lte=toi['end'],
                end_time__gte=toi['start'],
            )
        if aoi:
            bbox_geom = Polygon.from_bbox((
                aoi['left'] - TOLERANCE,
                aoi['bottom'] - TOLERANCE,
                aoi['right'] + TOLERANCE,
                aoi['top'] + TOLERANCE,
            ))
            coverages = coverages.filter(
                footprint__intersects=bbox_geom,
                #footprint__within=bbox_geom,
            )

        return 200, [
            coverage_serialize_extra(cov, [('in', cov.identifier in included)])
            for cov in coverages.order_by('begin_time', 'end_time')
        ]


@error_handler
@authorisation
@method_allow_conditional(['GET', 'DELETE'], ['GET'], is_time_series_owned)
@rest_json(JSON_OPTS)
def time_series_coverage_view(method, input_, user, identifier, coverage,
                              **kwargs):
    """ Handle a requested item of the time series.
    """
    try:
        obj = get_time_series(user).get(eoobj__identifier=identifier)
        cov = get_coverages(obj.eoobj).get(identifier=coverage)
    except ObjectDoesNotExist:
        raise HttpError(404, "Not found")

    if method == "DELETE":
        obj.eoobj.remove(cov)
        return 204, None

    return 200, coverage_serialize(cov)
