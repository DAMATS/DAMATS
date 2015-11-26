#-------------------------------------------------------------------------------
#
#  Object Validating Parsers
#  Used to validate parsed JSON input.
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

def _parse(parsers, value):
    """ Parse value using single (one object) or multiple parsers
    (sequence or iterable).
    """
    message = "Parsing failed!"
    try:
        for parser in parsers:
            try:
                return parser, value
            except (TypeError, ValueError) as exc:
                message = str(exc)
    except TypeError:
        return parsers(value)
    raise ValueError(message)

class Null(object):
    """ Null parser. """
    @staticmethod
    def parse(value):
        """ parse null value """
        if value is not None:
            raise ValueError("Not a null literal!")
        return value

class String(object):
    """ String parser. """
    @staticmethod
    def parse(value):
        """ parse string value """
        if not isinstance(value, basestring):
            raise ValueError("Not a string literal!")
        return value

class Array(object):
    """ Array parser. """
    def __init__(self, item_parser):
        self.item_parser = item_parser

    def parse(self, sequence):
        """ parse array """
        output = []
        for item in sequence:
            output.append(_parse(self.item_parser, item))
        return output

class Object(object):
    """ Object parser. """
    def __init__(self, schema):
        if isinstance(schema, dict):
            schema = schema.items()
        self.schema = schema

    def parse(self, obj):
        """ parse object """
        output = {}
        for key, parser in self.schema:
            if obj.has_key(key):
                output[key] = _parse(parser.parse, obj[key])
        return output
