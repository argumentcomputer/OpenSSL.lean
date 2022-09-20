namespace OpenSSL

opaque SslClientPointed : NonemptyType

def SslClient := SslClientPointed.type

noncomputable instance : Inhabited SslClient :=
  ⟨Classical.choice SslClientPointed.property⟩

@[extern "ssl_init"]
opaque sslInit : (certfile : @& String) → (keyfile : @& String) → IO Unit

@[extern "ssl_client_init"]
opaque sslClientInit : IO SslClient
