import OpenSSL

open OpenSSL

def main (args : List String) : IO UInt32 := do
  try
    OpenSSL.initLib ()
    let ctx ← Context.init ()
    let ssl ← ctx.initSSL
    pure 0
  catch e =>
    IO.eprintln <| "error: " ++ toString e -- avoid "uncaught exception: ..."
    pure 1

