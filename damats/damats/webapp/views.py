#-------------------------------------------------------------------------------
#
#  DAMATS web app Django views
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

#import json
from collections import OrderedDict

#from django.conf import settings
#from django.http import HttpResponse
from django.db.models import Q
from django.core.exceptions import ObjectDoesNotExist

from damats.webapp.models import (
    User, SourceSeries, TimeSeries, Process, Job, #Result,
)
from damats.util.object_parser import (
    Object, String,
)
from damats.util.view_utils import (
    HttpError, error_handler, method_allow, #ip_allow, ip_deny,
    rest_json,
)
from damats.util.config import WEBAPP_CONFIG
#from eoxserver.resources.coverages.models import (
#    RectifiedDataset, ReferenceableDataset
#)

# JSON formating options
#JSON_OPTS={}
JSON_OPTS = {'sort_keys': False, 'indent': 4, 'separators': (',', ': ')}

JOB_STATUS_DICT = dict(Job.STATUS_CHOICES)

#-------------------------------------------------------------------------------
# authentication decorator

def authorisation(view):
    """ Check if request.META['REMOTE_USER'] is an authorided DAMATS user
        and the User object in the view parameters.
    """
    def _wrapper_(request, *args, **kwargs):
        # NOTE: Default user is is read from the configuration.
        uid = request.META.get('REMOTE_USER', WEBAPP_CONFIG.default_user)
        try:
            user = (
                User.objects
                .prefetch_related('groups')
                .get(identifier=uid, locked=False)
            )
        except ObjectDoesNotExist:
            raise HttpError(401, "Unauthorised")
        return view(request, user, *args, **kwargs)
    _wrapper_.__name__ = view.__name__
    _wrapper_.__doc__ = view.__doc__
    return _wrapper_


#-------------------------------------------------------------------------------
# Input parsers

USER_PARSER = Object((
    ('name', String),
    ('description', String),
))

#-------------------------------------------------------------------------------
def get_sources(user):
    """ Get query set of all SourceSeries objects accessible by the user. """
    id_list = [user.identifier] + [obj.identifier for obj in user.groups.all()]
    return (
        SourceSeries.objects
        .select_related('eoobj')
        .filter(readers__identifier__in=id_list)
    )

def get_processes(user):
    """ Get query set of all Process objects accessible by the user. """
    id_list = [user.identifier] + [obj.identifier for obj in user.groups.all()]
    return Process.objects.filter(readers__identifier__in=id_list)

def get_time_series(user, owned=True, read_only=True):
    """ Get query set of TimeSeries objects accessible by the user.
        By default both owned and read-only (items shared by a different users)
        are returned.
    """
    id_list = [user.identifier] + [obj.identifier for obj in user.groups.all()]
    qset = TimeSeries.objects.select_related('eoobj', 'owner')
    if owned and read_only:
        qset = qset.filter(Q(owner=user) | Q(readers__identifier__in=id_list))
    elif owned:
        qset = qset.filter(owner=user)
    elif read_only:
        qset = qset.filter(readers__identifier__in=id_list)
    else: #nothing selected
        return []
    return qset

def get_jobs(user, owned=True, read_only=True):
    """ Get query set of Job objects accessible by the user.
        By default both owned and read-only (items shared by a different users)
        are returned.
    """
    id_list = [user.identifier] + [obj.identifier for obj in user.groups.all()]
    qset = Job.objects.select_related('owner')
    if owned and read_only:
        qset = qset.filter(Q(owner=user) | Q(readers__identifier__in=id_list))
    elif owned:
        qset = qset.filter(owner=user)
    elif read_only:
        qset = qset.filter(readers__identifier__in=id_list)
    else: #nothing selected
        return []
    return qset


# TEST VIEW - TO BE REMOVED
@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS, USER_PARSER)
def user_profile(method, input_, user):
    """ DAMATS user profile view.
    """
    user_id = user.identifier
    groups = [obj.identifier for obj in user.groups.all()]
    sources = [
        OrderedDict((
            ("identifier", obj.eoobj.identifier),
            ("name", obj.name),
            ("description", obj.description),
        )) for obj in get_sources(user)
    ]
    time_series = [
        OrderedDict((
            ("identifier", obj.eoobj.identifier),
            ("name", obj.name),
            ("description", obj.description),
            ("is_owner", obj.owner.identifier == user_id),
        )) for obj in get_time_series(user)
    ]
    processes = [
        OrderedDict((
            ("identifier", obj.identifier),
            ("name", obj.name),
            ("description", obj.description),
        )) for obj in get_processes(user)
    ]
    jobs = [
        OrderedDict((
            ("identifier", obj.identifier),
            ("name", obj.name),
            ("description", obj.description),
            ("status", JOB_STATUS_DICT[obj.status]),
            ("is_owner", obj.owner.identifier == user_id),
        )) for obj in get_jobs(user)
    ]
    return OrderedDict((
        ("identifier", user_id),
        ("name", user.name),
        ("description", user.description),
        ("groups", groups),
        ("sources", sources),
        ("processes", processes),
        ("time_series", time_series),
        ("jobs", jobs),
    ))


@error_handler
@authorisation
@method_allow(['GET', 'POST', 'PUT'])
@rest_json(JSON_OPTS, USER_PARSER)
def user_view(method, input_, user, **kwargs):
    """ User profile interface.
    """
    if method in ("POST", "PUT"):
        if input_.has_key("name"):
            user.name = input_.get("name", None) or None
        if input_.has_key("description"):
            user.description = input_.get("description", None) or None
        user.save()

    return {
        "identifier": user.identifier,
        "name": user.name or None,
        "description": user.description or None,
    }


@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS)
def groups_view(method, input_, user):
    """ User groups interface.
    """
    response = []
    for obj in user.groups.all():
        response.append({
            "identifier": obj.identifier,
            "name": obj.name or None,
            "description": obj.description or None,
        })
    return response


@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS)
def sources_view(method, input_, user):
    """ List avaiable sources.
    """
    response = []
    for obj in get_sources(user):
        response.append({
            "identifier": obj.eoobj.identifier,
            "name": obj.name or None,
            "description": obj.description or None,
        })
    return response


@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS)
def processes_view(method, input_, user):
    """ List avaiable processes.
    """
    response = []
    for obj in get_processes(user):
        item = {
            "identifier": obj.identifier,
        }
        if obj.name:
            item['name'] = obj.name
        if obj.description:
            item['description'] = obj.description
        response.append(item)
    return response


@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS)
def time_series_view(method, input_, user):
    """ List avaiable time-series.
    """
    response = []
    for obj in get_time_series(user):
        response.append({
            "identifier": obj.eoobj.identifier,
            "name": obj.name or None,
            "description": obj.description or None,
            "read_only": obj.owner != user,
        })
    return response


@error_handler
@authorisation
@method_allow(['GET'])
@rest_json(JSON_OPTS)
def jobs_view(method, input_, user, identifier=None):
    """ List avaiable time-series.
    """
    response = []
    for obj in get_jobs(user):
        item = {
            "identifier": obj.identifier,
            "read_only": obj.owner != user,
            "status": JOB_STATUS_DICT[obj.status],
        }
        if obj.name:
            item['name'] = obj.name
        if obj.description:
            item['description'] = obj.description
        response.append(item)
    return response
