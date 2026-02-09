# (Be in -*- python -*- mode.)
#
# ====================================================================
# Copyright (c) 2007-2010 CollabNet.  All rights reserved.
#
# This software is licensed as described in the file COPYING, which
# you should have received as part of this distribution.
#
# This software consists of voluntary contributions made by many
# individuals.  For exact contribution history, see the revision
# history and logs.
# ====================================================================

"""Expand RCS/CVS keywords."""


import re
import time

from cvs2svn_lib.context import Ctx


class _KeywordExpander:
  """A class whose instances provide substitutions for CVS keywords.

  This class is used via its __call__() method, which should be called
  with a match object representing a match for a CVS keyword string.
  The method returns the replacement for the matched text.

  The __call__() method works by calling the method with the same name
  as that of the CVS keyword (converted to lower case).

  Instances of this class can be passed as the REPL argument to
  re.sub()."""

  date_fmt_old = "%Y/%m/%d %H:%M:%S"    # CVS 1.11, rcs
  date_fmt_new = "%Y-%m-%d %H:%M:%S"    # CVS 1.12

  date_fmt = date_fmt_new

  @classmethod
  def use_old_date_format(klass):
      """Class method to ensure exact compatibility with CVS 1.11
      output.  Use this if you want to verify your conversion and you're
      using CVS 1.11."""
      klass.date_fmt = klass.date_fmt_old

  def __init__(self, cvs_rev):
    self.cvs_rev = cvs_rev

  def __call__(self, match):
    keyword = match.group(1)
    
    if isinstance(keyword, bytes):
      # Bytes mode
      func_name = keyword.decode('ascii').lower()
      value = getattr(self, func_name)()
      if isinstance(value, str):
        value = value.encode('utf-8')
      return b'$%s: %s $' % (keyword, value)
    else:
      # String mode
      func_name = keyword.lower()
      value = getattr(self, func_name)()
      # value is expected to be str, keyword is str
      return '$%s: %s $' % (keyword, value)

  def author(self):
    return Ctx()._metadata_db[self.cvs_rev.metadata_id].original_author

  def date(self):
    return time.strftime(self.date_fmt, time.gmtime(self.cvs_rev.timestamp))

  def header(self):
    return '%s %s %s %s Exp' % (
        self.source(), self.cvs_rev.rev, self.date(), self.author(),
        )

  def id(self):
    return '%s %s %s %s Exp' % (
        self.rcsfile(), self.cvs_rev.rev, self.date(), self.author(),
        )

  def locker(self):
    # Handle kvl like kv, as a converted repo is supposed to have no
    # locks.
    return ''

  def log(self):
    # Would need some special handling.
    return 'not supported by cvs2svn'

  def name(self):
    # Cannot work, as just creating a new symbol does not check out
    # the revision again.
    return 'not supported by cvs2svn'

  def rcsfile(self):
    return self.cvs_rev.cvs_file.rcs_basename + ",v"

  def revision(self):
    return self.cvs_rev.rev

  def source(self):
    project = self.cvs_rev.cvs_file.project
    return '%s/%s%s' % (
        project.cvs_repository_root,
        project.cvs_module,
        '/'.join(self.cvs_rev.cvs_file.get_path_components(rcs=True)),
        )

  def state(self):
    # We check out only live revisions.
    return 'Exp'


# Define keywords base string
_kws_base = 'Author|Date|Header|Id|Locker|Log|Name|RCSfile|Revision|Source|State'

# Byte-oriented regexes
_kws_bytes = _kws_base.encode('ascii')
_kw_re_bytes = re.compile(rb'\$(' + _kws_bytes + rb'):[^$\n]*\$')
_kwo_re_bytes = re.compile(rb'\$(' + _kws_bytes + rb')(:[^$\n]*)?\$')

# String-oriented regexes
_kw_re_str = re.compile(r'\$(' + _kws_base + r'):[^$\n]*\$')
_kwo_re_str = re.compile(r'\$(' + _kws_base + r')(:[^$\n]*)?\$')


def expand_keywords(text, cvs_rev):
  """Return TEXT with keywords expanded for CVS_REV.

  E.g., '$Author$' -> '$Author: jrandom $'."""

  if isinstance(text, bytes):
    return _kwo_re_bytes.sub(_KeywordExpander(cvs_rev), text)
  else:
    return _kwo_re_str.sub(_KeywordExpander(cvs_rev), text)


def collapse_keywords(text):
  """Return TEXT with keywords collapsed.

  E.g., '$Author: jrandom $' -> '$Author$'."""

  if isinstance(text, bytes):
    return _kw_re_bytes.sub(rb'$\1$', text)
  else:
    return _kw_re_str.sub(r'$\1$', text)