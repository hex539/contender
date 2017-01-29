package Judge::View::SourceCode;
use Moose;
use namespace::autoclean;

use Database;
use File::Slurp;
use File::Spec::Functions;
use HTML::Defang;
use HTML::Entities;
use Judge::Model::Problem;
use Settings;
use Text::Xslate qw(mark_raw);
use Judge::Model::User;
use feature 'state';

# BEGIN { extends 'Catalyst::View'; }

sub format_table {{
  Alert => ["<font color=\"#0000ff\">", "</font>"],
  BaseN => ["<font color=\"#007f00\">", "</font>"],
  BString => ["<font color=\"#c9a7ff\">", "</font>"],
  Char => ["<font color=\"#ff00ff\">", "</font>"],
  Comment => ["<font color=\"#7f7f7f\"><i>", "</i></font>"],
  DataType => ["<font color=\"#0000ff\">", "</font>"],
  DecVal => ["<font color=\"#00007f\">", "</font>"],
  Error => ["<font color=\"#ff0000\"><b><i>", "</i></b></font>"],
  Float => ["<font color=\"#00007f\">", "</font>"],
  Function => ["<font color=\"#007f00\">", "</font>"],
  IString => ["<font color=\"#ff0000\">", ""],
  Keyword => ["<b>", "</b>"],
  Normal => ["", ""],
  Operator => ["<font color=\"#ffa500\">", "</font>"],
  Others => ["<font color=\"#b03060\">", "</font>"],
  RegionMarker => ["<font color=\"#96b9ff\"><i>", "</i></font>"],
  Reserved => ["<font color=\"#9b30ff\"><b>", "</b></font>"],
  String => ["<font color=\"#ff0000\">", "</font>"],
  Variable => ["<font color=\"#0000ff\"><b>", "</b></font>"],
  Warning => ["<font color=\"#0000ff\"><b><i>", "</b></i></font>"],
}}

sub highlighter {
  @_ == 1 or die;
  my $ext = shift;

  state %memo;

  if (not exists $memo{$ext}) {
    state $substitutions = {
     "<" => "&lt;",
     ">" => "&gt;",
     "&" => "&amp;",
     "\t" => "  ",
    };
    my @hl_args = (substitutions => $substitutions, format_table => format_table);

    my $hl = undef;
    eval {
      if ($ext eq 'py' or $ext eq 'pypy' or $ext eq 'python') {
        use Syntax::Highlight::Engine::Kate::Python;
        $hl = new Syntax::Highlight::Engine::Kate::Python(@hl_args);
      }
      elsif ($ext eq 'cc' or $ext eq 'c' or $ext eq 'cpp' or $ext eq 'cxx') {
        use Syntax::Highlight::Engine::Kate::Cplusplus;
        $hl = new Syntax::Highlight::Engine::Kate::Cplusplus(@hl_args);
      }
      elsif ($ext eq 'java') {
        use Syntax::Highlight::Engine::Kate::Java;
        $hl = new Syntax::Highlight::Engine::Kate::Java(@hl_args);
      }
      elsif ($ext eq 'matlab' or $ext eq 'm' or $ext eq 'octave') {
        use Syntax::Highlight::Engine::Kate::Matlab;
        $hl = new Syntax::Highlight::Engine::Kate::Matlab(@hl_args);
      }
    };

    if (defined $hl) {
      $memo{$ext} = $hl;
    }
  }

  return $memo{$ext};
}

1;
