
namespace OpenSSL

constant SslClientPointed : PointedType

def SslClient : Type := SslClientPointed.type

instance : Inhabited SslClient := ⟨SslClientPointed.val⟩

@[extern "ssl_init"]
constant sslInit : (certfile : @& String) → (keyfile : @& String) → IO Unit

@[extern "ssl_client_init"]
constant sslClientInit : IO SslClient
