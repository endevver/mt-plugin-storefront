#!/usr/bin/perl -w

use strict;
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/plugins/StoreFront/lib" : 'plugins/StoreFront/lib';
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : 'lib';
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/extlib" : 'extlib';
use MT::Bootstrap App => 'StoreFront::PayPal::App';
