#-------------------------------------------------------------------------------
#
# DJango View Utilities
#
# Authors: Martin Paces <martin.paces@eox.at>
#
#-------------------------------------------------------------------------------
# Copyright (C) 2014 EOX IT Services GmbH
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

import sys
import ipaddr
import traceback
from django.http import HttpResponse
from django.conf import settings

class HttpError(Exception):
    """ Simple HTTP error exception """
    def __init__(self, status, message):
        Exception.__init__(self, message)
        self.status = status
        self.message = message

    def __unicode__(self):
        return "%d %s"%(self.status, self.message)


def error_handler(view):
    """ error handling decorator """
    def _wrapper_(request):
        try:
            return view(request)
        except HttpError as exc:
            response = HttpResponse(unicode(exc), content_type="text/plain")
            response.status_code = exc.status
        except Exception as exc:
            message = "Internal Server Error"
            trace = traceback.format_exc()
            sys.stderr.write(trace)
            if settings.DEBUG:
                message = "%s\n\n%s" % (message, trace)
            response = HttpResponse(message, content_type="text/plain")
            response.status_code = 500
        return response
    _wrapper_.__name__ = view.__name__
    _wrapper_.__doc__ = view.__doc__
    return _wrapper_


def method_allow(method_list):
    """ reject non-supported HTTP methods """
    def _wrap_(view):
        def _wrapper_(request):
            if request.method not in method_list:
                raise HttpError(
                    405, "Error: Method not supported! "
                    "METHOD='%s'" % request.method
                )
            return view(request)
        _wrapper_.__name__ = view.__name__
        _wrapper_.__doc__ = view.__doc__
        return _wrapper_
    return _wrap_


def ip_deny(ip_list):
    """ IP black-list restricted access """
    def _wrap_(view):
        def _wrapper_(request):
            # get request source address and compare it with the forbiden ones
            ip_src = ipaddr.IPAddress(request.META['REMOTE_ADDR'])
            for ip_ in ip_list:
                if ip_src in ipaddr.IPNetwork(ip_):
                    raise HttpError(403, "Forbiden!")
            return view(request)
        _wrapper_.__name__ = view.__name__
        _wrapper_.__doc__ = view.__doc__
        return _wrapper_
    return _wrap_


def ip_allow(ip_list):
    """ IP white-list restricted access """
    def _wrap_(view):
        def _wrapper_(request):
            # get request source address and compare it with the allowed ones
            ip_src = ipaddr.IPAddress(request.META['REMOTE_ADDR'])
            for ip_ in ip_list:
                if ip_src in ipaddr.IPNetwork(ip_):
                    break
            else:
                raise HttpError(403, "Forbiden!")
            return view(request)
        _wrapper_.__name__ = view.__name__
        _wrapper_.__doc__ = view.__doc__
        return _wrapper_
    return _wrap_
