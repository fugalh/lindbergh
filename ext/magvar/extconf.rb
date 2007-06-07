require 'mkmf'
# If your compiler is not g++, you probably need to change this
CONFIG['LDSHARED'] = "g++ -shared"
create_makefile 'magvar'
