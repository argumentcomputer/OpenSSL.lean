import OpenSSL

open OpenSSL

def main (args : List String) : IO UInt32 := do
  try
    let ctx ← Context.init
    let ssl ← ctx.initSSL
    ssl.setConnectState
    let wbio ← BIO.init
    let rbio ← BIO.init
    ssl.setReadBIO rbio
    ssl.setWriteBIO wbio
    if ← ssl.isInitFinished then
      println! "SSL init finished"
    else
      println! "SSL init not finished"

    pure 0
  catch e =>
    IO.eprintln <| "error: " ++ toString e
    pure 1

