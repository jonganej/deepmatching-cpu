CC=g++
PYTHON_VERSION=3.5
OS_NAME=$(shell uname -s)

ifeq ($(OS_NAME),Linux) 
  LAPACKLDFLAGS=-L/usr/lib -latlas   # single-threaded blas
  #LAPACKLDFLAGS=/usr/lib64/atlas/libtatlas.so  # multi-threaded blas
  BLAS_THREADING=-D MULTITHREADED_BLAS # remove this if wrong
endif
ifeq ($(OS_NAME),Darwin)  # Mac OS X
  LAPACKLDFLAGS=-framework Accelerate # for OS X
endif
LAPACKCFLAGS=-Dinteger=int $(BLAS_THREADING)
LIB_DIR_X86=/usr/lib/x86_64-linux-gnu
STATICLAPACKLDFLAGS=-fPIC -Wall -g -fopenmp -static -static-libstdc++ $(LIB_DIR_X86)/libjpeg.a $(LIB_DIR_X86)/libpng.a $(LIB_DIR_X86)/libz.a /usr/lib/libblas.a /usr/lib/gcc/x86_64-linux-gnu/5/libgfortran.a /usr/lib/gcc/x86_64-linux-gnu/5/libquadmath.a # statically linked version

CFLAGS= -fPIC -Wall -g -std=c++11 $(LAPACKCFLAGS) -fopenmp -DUSE_OPENMP -O3
LDFLAGS=-fPIC -Wall -g -lpng -ljpeg -fopenmp -lblas -lgfortran -lquadmath 
CPYTHONFLAGS=-I/usr/include/python$(PYTHON_VERSION) $(shell python$(PYTHON_VERSION)-config --cflags)

SOURCES := $(shell find . -name '*.cpp' ! -name 'deepmatching_matlab.cpp')
OBJ := $(SOURCES:%.cpp=%.o)
HEADERS := $(shell find . -name '*.h')


all: deepmatching 

.cpp.o:  %.cpp %.h
	$(CC) -o $@ $(CFLAGS) -c $+

deepmatching: $(HEADERS) $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS) $(LAPACKLDFLAGS)

#deepmatching: $(HEADERS) $(OBJ) 
#	$(CC) -shared -Wl,-soname,libdeepmatching.so.1 -o libdeepmatching.so $(LDFLAGS) $(LAPACKLDFLAGS) $^ 
##	ar rcs libdeepmatching.a $^
#	$(CC) -o $@ -L. -ldeepmatching $(LDFLAGS) $(LAPACKLDFLAGS)

deepmatching-static: $(HEADERS) $(OBJ)
	$(CC) -o $@ $^ $(STATICLAPACKLDFLAGS)

python: $(HEADERS) $(OBJ)
#	swig -python -I/usr/include/python3.5 deepmatching.i # not necessary, only do if you have swig compiler
	g++ $(CFLAGS) -c deepmatching_wrap.c $(CPYTHONFLAGS)
	$(CC) -Wl,--no-undefined -shared -o _deepmatching.so deepmatching_wrap.o $(OBJ) $(LDFLAGS) $(LAPACKLDFLAGS) $(shell python$(PYTHON_VERSION)-config --ldflags)
#	g++ -Wl,--verbose -shared $(LDFLAGS) $(LAPACKLDFLAGS) deepmatching_wrap.o $(OBJ) -o deepmatching.so $(LIBFLAGS) 

clean:
	rm -f $(OBJ) libdeepmatching*  deepmatching *~ *.pyc .gdb_history deepmatching_wrap.o deepmatching.so deepmatching.mex???

