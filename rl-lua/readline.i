%module readline
%{
#include <readline/readline.h>
#include <readline/history.h>
%}
%include "readline.h"
%include "history.h"
