r"""
Utility functions for the interface with dot2tex

TESTS:

We check that dot2tex supports neato, and in particular floats as
positions. See `<http://code.google.com/p/dot2tex/issues/detail?id=20>`_::

    sage: graph = 'digraph {\n  "11,1" [label="(\'11\', 1)"];\n  "10,2" [label="(\'10\', 2)"];\n  "01,2" [label="(\'01\', 2)"];\n  "11,0" [label="(\'11\', 0)"];\n  "01,0" [label="(\'01\', 0)"];\n  "01,1" [label="(\'01\', 1)"];\n  "00,1" [label="(\'00\', 1)"];\n  "10,1" [label="(\'10\', 1)"];\n  "00,0" [label="(\'00\', 0)"];\n  "00,2" [label="(\'00\', 2)"];\n  "10,0" [label="(\'10\', 0)"];\n  "11,2" [label="(\'11\', 2)"];\n\nedge [color="black"];\n  "11,1" -> "10,2";\n  "11,1" -> "11,2";\n  "11,0" -> "11,1";\n "11,0" -> "01,1";\n  "01,0" -> "11,1";\n  "01,0" -> "01,1";\n  "01,1" -> "01,2";\n  "01,1" -> "00,2";\n  "00,1" -> "01,2";\n  "00,1" -> "00,2";\n  "10,1" -> "10,2";\n  "10,1" -> "11,2";\n  "00,0" -> "00,1";\n  "00,0" -> "10,1";\n  "10,0" -> "00,1";\n  "10,0" -> "10,1";\n}'
    sage: import dot2tex                                                    # optional - dot2tex graphviz
    sage: output = dot2tex.dot2tex(graph, format="positions", prog="neato") # optional - dot2tex graphviz
    sage: sorted(output.keys())                                             # optional - dot2tex graphviz
    ['00,0', '00,1', '00,2',
     '01,0', '01,1', '01,2',
     '10,0', '10,1', '10,2',
     '11,0', '11,1', '11,2']
    sage: assert isinstance(output, dict)                                   # optional - dot2tex graphviz
    sage: assert all(isinstance(position, list) for position in output.values()) # optional - dot2tex graphviz
    sage: assert all(isinstance(c, float) for position in output.values() for c in position ) # optional - dot2tex graphviz
"""
#*****************************************************************************
#      Copyright (C) 2010-2013   Nicolas M. Thiery <nicolas.thiery at u-psud.fr>
#
#  Distributed under the terms of the GNU General Public License (GPL)
#                  http://www.gnu.org/licenses/
#*****************************************************************************

import re
from sage.misc.latex import latex

def have_dot2tex():
    """
    Return whether ``dot2tex`` >= 2.8.7 and graphviz are installed and functional.

    EXAMPLES::

        sage: sage.graphs.dot2tex_utils.have_dot2tex() # optional - dot2tex graphviz
        True
        sage: sage.graphs.dot2tex_utils.have_dot2tex() in [True, False]
        True
    """
    try:
        import dot2tex
        # Test for this required feature from dot2tex 2.8.7
        return dot2tex.dot2tex("graph {}", format = "positions") == {}
    except Exception:
        return False
    return True

def assert_have_dot2tex():
    """
    Test whether ``dot2tex`` >= 2.8.7 and graphviz are installed and
    functional, and raise an error otherwise.

    EXAMPLES::

        sage: sage.graphs.dot2tex_utils.assert_have_dot2tex() # optional - dot2tex graphviz
    """
    check_error_string = """
An error occurs while testing the dot2tex installation.

Please see :meth:`sage.graphs.generic_graph.GenericGraph.layout_graphviz`
and check the installation of graphviz and of the dot2tex spkg.

For support, please contact <sage-combinat-devel at googlegroups.com>.
"""
    missing_error_string = """
dot2tex not available.

Please see :meth:`sage.graphs.generic_graph.GenericGraph.layout_graphviz`
for installation instructions.
"""
    try:
        import dot2tex
        if dot2tex.dot2tex("graph {}", format = "positions") != {}:
            raise RuntimeError(check_error_string)
    except ImportError:
        raise RuntimeError(missing_error_string)

def quoted_latex(x):
    r"""
    Strip the latex representation of ``x`` to make it suitable for ``dot2tex``.

    This strips out newlines, comments, and ``"`` quotes. It also
    replaces ``\verb`` macros by ``\text`` (dot2tex currently does not
    support ``\verb``). The special caracters ``{}_^`` inside
    ``\verb`` are replaced by spaces.

    EXAMPLES::

        sage: print sage.graphs.dot2tex_utils.quoted_latex(matrix([[1,1],[0,1],[0,0]]))
        \left(\begin{array}{rr}1 & 1 \\0 & 1 \\0 & 0\end{array}\right)
        sage: print sage.graphs.dot2tex_utils.quoted_latex("coucou")
        \text{coucou}
        sage: print sage.graphs.dot2tex_utils.quoted_latex("coucou coucou")
        \text{coucou}\phantom{\text{x}}\text{coucou}
        sage: print sage.graphs.dot2tex_utils.quoted_latex("coucou_coucou{bla^3{}")
        \text{coucou coucou bla 3  }
        sage: print sage.graphs.dot2tex_utils.quoted_latex("1 0 0\n  1 0\n    1")
        \begin{array}{l}\text{1}\phantom{\text{x}}\text{0}\phantom{\text{x}}\text{0}\\\phantom{\text{xx}}\text{1}\phantom{\text{x}}\text{0}\\\phantom{\text{xxxx}}\text{1}\end{array}
    """
    result = latex(x)
    def text(matchobj):
        s = matchobj.group(2)
        return r"\text{%s}"%(re.sub(r"[_^{}]", " ", s))
    result = re.sub(r"\\verb(.)(.*?)\1", text, result)
    result = re.sub("\"|\r|(%[^\n]*)?\n","", result)
    return result

def quoted_str(x):
    r"""
    Strip the string representation of ``x`` to make it suitable for ``dot2tex``.

    This is especially used for node labels (``dot2tex`` gets confused
    by newlines and braces).

    EXAMPLES::

        sage: sage.graphs.dot2tex_utils.quoted_str(matrix([[1,1],[0,1],[0,0]]))
        '[1 1]\\n\\\n[0 1]\\n\\\n[0 0]'
        sage: print sage.graphs.dot2tex_utils.quoted_str(matrix([[1,1],[0,1],[0,0]]))
        [1 1]\n\
        [0 1]\n\
        [0 0]
    """
    return re.sub("\n",r"\\n\\"+"\n", re.sub("\"|\r|}|{","", str(x)))

        sage: sage.graphs.dot2tex_utils.key("blah{bleh}\nbl.ih{")
    return re.sub("[\\\'\"\[\]() \t\r\n{}.]","", str(x))
    Same as :func:`key`, except that the hash of the object is
