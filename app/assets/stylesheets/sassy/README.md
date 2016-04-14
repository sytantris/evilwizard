SY'S SCSS LIBRARY
-----------------

@todo:
• test `_include.scss`
• test mixins in `_mixin-test.scss`
• account for changes added by Refinery and Foundation
• standardize header


SASS VARIABLES & MIXINS
-----------------------

Importing SCSS files prefixed with an underscore (such as \_media.scss)
without the underscore (such as import 'media'; tells the compiler that
these are mixin files and the content isn't duplicated, rather substituted in.

These files need to be imported into every SCSS file where their functions or variables are used.

\_media.scss:
-------------
A library of easy media queries and common viewport widths.
to import: import 'media.scss'

Along wth a set of variables representing common device widths, this
file comes with four handy mixins for creating media queries.

@mixin respond-to-max ($max)
  Given a maximum width, this mixin will create a media query for all
  widths less than or equal to that width.
    Usage:
      @include respond-to-max(768px) { insert SCSS here }

@mixin respond-to-min ($min)
  Given a minimum width, this mixin will create a mediq query for all
  widths greater than that width.
    Usage:
      @include respond-to-min(480px) { insert SCSS here }

@mixin respond-to-interval ($min, $max)
  Given a minimum and a maximum value, this mixin will create a media query
  for all widths such that $min > mixin >= $max.
    Usage:
      @include respond-to-interval(768px, 1024px) { insert SCSS here }

@mixin respond-to-print ($hidden...)
  Given a comma-separated list of selectors as arguments, this mixin will
  create a media query for print with each given selector set to
  'display: none'.  It will also render whatever content is given in the
  block.  Note that id and class selectors must be passed in quotes or
  Sass will yell.
  With elements the quotes are optional.
    Usage:
      @include respond-to-print(header, nav, '.menu', '#sidebar') { insert SCSS here }
