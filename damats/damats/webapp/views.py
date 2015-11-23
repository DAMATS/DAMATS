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
# pylint: disable=missing-docstring

import json
from collections import OrderedDict

#from django.conf import settings
from django.http import HttpResponse
from django.db.models import Q
from django.core.exceptions import ObjectDoesNotExist

from damats.webapp.models import (
    User, SourceSeries, TimeSeries, Process, Job, #Result,
)
from damats.util.view_utils import (
    HttpError, error_handler, method_allow, #ip_allow, ip_deny,
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
def get_authorised_user(request):
    """ Check if request.META['REMOTE_USER'] is an authorided DAMATS user
        and return the User object.
    """
    # NOTE: Default user is is read from the configuration.
    uid = request.META.get('REMOTE_USER', WEBAPP_CONFIG.default_user)
    try:
        return (
            User.objects
            .prefetch_related('groups')
            .get(identifier=uid, locked=False)
        )
    except ObjectDoesNotExist:
        raise HttpError(401, "Unauthorised")

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

#-------------------------------------------------------------------------------
@error_handler
@method_allow(['GET'])
def user_profile(request):
    """ DAMATS user profile view.
    """
    user = get_authorised_user(request)
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
    response = OrderedDict((
        ("identifier", user_id),
        ("name", user.name),
        ("description", user.description),
        ("groups", groups),
        ("sources", sources),
        ("processes", processes),
        ("time_series", time_series),
        ("jobs", jobs),
    ))

    return HttpResponse(
        json.dumps(response, **JSON_OPTS), content_type="application/json"
    )

@error_handler
@method_allow(['GET'])
def user_view(request):
    """ User profile interface.
    """
    user = get_authorised_user(request)
    user_id = user.identifier

    ##if request.method == "GET":

    response = OrderedDict((
        ("identifier", user.identifier),
        ("name", user.name),
        ("description", user.description),
    ))

    return HttpResponse(
        json.dumps(response, **JSON_OPTS), content_type="application/json"
    )

@error_handler
@method_allow(['GET'])
def groups_view(request):
    """ User groups interface.
    """
    user = get_authorised_user(request)
    user_id = user.identifier

    ##if request.method == "GET":

    response = []
    for group in user.groups.all():
        response.append(OrderedDict((
            ("identifier", user.identifier),
            ("name", user.name),
            ("description", user.description),
        )))

    return HttpResponse(
        json.dumps(response, **JSON_OPTS), content_type="application/json"
    )

@error_handler
@method_allow(['GET'])
def sources_view(request):
    """ List avaiable sources.
    """
    user = get_authorised_user(request)
    response = []
    for obj in get_sources(user):
        item = {
            "identifier": obj.eoobj.identifier,
        }
        if obj.name:
            item['name'] = obj.name
        if obj.description:
            item['description'] = obj.description
        response.append(item)
    return HttpResponse(
        json.dumps(response, **JSON_OPTS), content_type="application/json"
    )

@error_handler
@method_allow(['GET'])
def processes_view(request):
    """ List avaiable processes.
    """
    user = get_authorised_user(request)
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
    return HttpResponse(
        json.dumps(response, **JSON_OPTS), content_type="application/json"
    )

@error_handler
@method_allow(['GET'])
def time_series_view(request):
    """ List avaiable time-series.
    """
    user = get_authorised_user(request)
    response = []
    for obj in get_time_series(user):
        item = {
            "identifier": obj.eoobj.identifier,
            "read_only": obj.owner != user,
        }
        if obj.name:
            item['name'] = obj.name
        if obj.description:
            item['description'] = obj.description
        response.append(item)
    return HttpResponse(
        json.dumps(response, **JSON_OPTS), content_type="application/json"
    )

@error_handler
@method_allow(['GET'])
def jobs_view(request, identifier=None):
    """ List avaiable time-series.
    """
    user = get_authorised_user(request)
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
    return HttpResponse(
        json.dumps(response, **JSON_OPTS), content_type="application/json"
    )
