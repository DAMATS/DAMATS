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
#from eoxserver.resources.coverages.models import (
#    RectifiedDataset, ReferenceableDataset
#)

# JSON formating options
#JSON_OPTS={}
JSON_OPTS = {'sort_keys': False, 'indent': 4, 'separators': (',', ': ')}

JOB_STATUS_DICT = dict(Job.STATUS_CHOICES)

def get_authorised_user(request):
    """ Check if request.META['REMOTE_USER'] is an authorided DAMATS user
        and return the User object.
    """
    uid = request.META.get('REMOTE_USER', "")
    try:
        return User.objects.get(identifier=uid, locked=False)
    except ObjectDoesNotExist:
        raise HttpError(403, "Access Denied")

@error_handler
@method_allow(['GET'])
def user_profile(request):
    """ DAMATS user profile view.
    """
    user = get_authorised_user(request)
    user_id = user.identifier
    groups = [obj.identifier for obj in user.groups.all()]
    id_list = ["user"] + groups
    sources = [
        OrderedDict((
            ("identifier", obj.eoobj.identifier),
            ("name", obj.name),
            ("description", obj.description),
        )) for obj in SourceSeries.objects.prefetch_related('eoobj').filter(
            readers__identifier__in=id_list
        )
    ]
    time_series = [
        OrderedDict((
            ("identifier", obj.eoobj.identifier),
            ("name", obj.name),
            ("description", obj.description),
            ("is_owner", obj.owner.identifier == user_id),
        )) for obj in TimeSeries.objects.prefetch_related('eoobj', 'owner')\
            .filter(
                Q(owner__identifier=id_list) |
                Q(readers__identifier__in=id_list)
            )
    ]
    processes = [
        OrderedDict((
            ("identifier", obj.identifier),
            ("name", obj.name),
            ("description", obj.description),
        )) for obj in Process.objects.filter(
            readers__identifier__in=id_list
        )
    ]
    jobs = [
        OrderedDict((
            ("identifier", obj.identifier),
            ("name", obj.name),
            ("description", obj.description),
            ("status", JOB_STATUS_DICT[obj.status]),
            ("is_owner", obj.owner.identifier == user_id),
        )) for obj in Job.objects.prefetch_related('owner').filter(
            Q(owner__identifier=id_list) |
            Q(readers__identifier__in=id_list)
        )
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
