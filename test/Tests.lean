import OpenSSL

open OpenSSL

partial def main (args : List String) : IO UInt32 := do
  try
    println! "Start"
    let ctx ← Context.init
    let host := "www.google.com"
    let bio ← ctx.newSSLConnect
    println! "ssl connect"
    let res ← bio.setConnHostname s!"{host}:443"
    let res ← bio.doConnect
    println! "connection started {res}"
    let res ← ctx.loadVerifyLocations "/etc/ssl/certs/ca-certificates.crt" "/etc/ssl/certs/"
    println! "verify locations {res}"
    let ssl ← bio.getSSL
    println! "load ssl"
    let res ← ssl.verifyResult
    println! "verify result {res}"
    let req := s!"GET / HTTP/1.1\r\n Host: {host}"
    bio.write req.toUTF8
    println! "Request sent: {req}"
    let rec read : ByteArray -> IO ByteArray := fun s => do
      let (b, ba) ← bio.read 1024
      -- println! "{String.fromUTF8Unchecked ba}"
      println! "Read line"
      let res := s ++ ba 
      if b then
        read res
      else
        pure res

    let res ← read ByteArray.empty
    -- if ← ssl.isInitFinished then
    --   println! "SSL init finished"
    -- else
    --   println! "SSL init not finished"

    pure 0
  catch e =>
    IO.eprintln <| "error: " ++ toString e
    pure 1

def test2 (args : List String) : IO UInt32 := do
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

