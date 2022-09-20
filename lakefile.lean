import Lake
open Lake DSL

package OpenSSL {
  precompileModules := true
  moreLinkArgs := #["-L", "-lssl", "-fPIC"]
}

@[defaultTarget]
lean_lib OpenSSL

def cDir   := "native"
def ffiSrc := "native.c"
def ffiO   := "ffi.o"
def ffiLib := "ffi"

target ffi.o (pkg : Package) : FilePath := do
  let oFile := pkg.buildDir / ffiO
  let srcJob ← inputFile <| pkg.dir / cDir / ffiSrc
  buildFileAfterDep oFile srcJob fun srcFile => do
    let flags := #["-I", (← getLeanIncludeDir).toString,
      "-I", "/usr/include/openssl"]
    compileO ffiSrc oFile srcFile flags

extern_lib ffi (pkg : Package) := do
  let name := nameToStaticLib ffiLib
  let ffiO ← fetch <| pkg.target ``ffi.o
  buildStaticLib (pkg.buildDir / "lib" / name) #[ffiO]
