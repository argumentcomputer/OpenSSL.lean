
namespace OpenSSL

/--
Initialize the OpenSSL library.
-/
@[extern "lean_ssl_lib_init"]
private opaque initLib: Unit → IO Unit

builtin_initialize initLib ()

opaque ContextPointed : NonemptyType

def Context : Type := ContextPointed.type

instance : Nonempty Context := ContextPointed.property

namespace Context

/--
Initialize a SSL context.
-/
@[extern "lean_ssl_ctx_init"]
opaque init : IO Context

/--
Use certificate file for SSL Context.
-/
@[extern "lean_ssl_ctx_use_certificate_file"]
opaque useCertificateFile : @& Context → @& String → IO Bool

/--
Use private key file for SSL Context.
-/
@[extern "lean_ssl_ctx_use_private_key_file"]
opaque usePrivateKeyFile : @& Context → @& String → IO Bool

/--
Check private key for SSL Context assuming it has been loaded.
-/
@[extern "lean_ssl_ctx_check_private_key"]
opaque checkPrivateKey : @& Context → @& String → IO Bool

/--
Set default locations for trusted CA certificates.
-/
@[extern "lean_ssl_ctx_load_verify_locations"]
opaque loadVerifyLocations : @& Context → @& String → @& String → IO Bool

end Context

opaque SSLPointed : NonemptyType

def SSL : Type := SSLPointed.type

instance : Nonempty SSL := SSLPointed.property

/--
Initialize a SSL struct.
-/
@[extern "lean_ssl_init"]
opaque Context.initSSL : @& Context → IO SSL

namespace SSL

inductive Status
  | ok
  | wantIO
  | fail
  deriving BEq, Hashable

/--
SSL_is_init_finished() returns 1 if the SSL/TLS connection
is in a state where fully protected application data can be transferred or 0 otherwise.
-/
@[extern "lean_ssl_is_init_finished"]
opaque isInitFinished: @& SSL → IO Bool

/--
Is the SSL connection set to be used as a server.
-/
@[extern "lean_ssl_is_server"]
opaque isServer: @& SSL → IO Bool

/--
Use as a server.
-/
@[extern "lean_ssl_set_accept_state"]
opaque setAcceptState: @& SSL → IO Unit

/--
Use as a client.
-/
@[extern "lean_ssl_set_connect_state"]
opaque setConnectState: @& SSL → IO Unit

/--
Write to connection.
-/
@[extern "lean_ssl_write"]
opaque write: @& SSL → @& ByteArray → IO Unit

/--
Read from connection.
-/
@[extern "lean_ssl_read"]
opaque read: @& SSL → USize → IO (Bool × ByteArray)

/--
Read from connection.
-/
@[extern "lean_ssl_verify_result"]
opaque verifyResult: @& SSL → IO UInt64

/--
Get error.
-/
@[extern "lean_ssl_get_error"]
opaque getError: @& SSL → UInt32 → IO UInt32

end SSL

-- BIO

opaque BIOPointed : NonemptyType

/--
Basic IO buffer
-/
def BIO : Type := BIOPointed.type

instance : Nonempty BIO := BIOPointed.property

/--
Set read BIO
-/
@[extern "lean_ssl_set_rbio"]
opaque SSL.setReadBIO : @& SSL → @& BIO → IO Unit

/--Set write BIO
-/
@[extern "lean_ssl_set_wbio"]
opaque SSL.setWriteBIO : @& SSL → @& BIO → IO Unit

/--
Create a new SSL connection BIO
-/
@[extern "lean_bio_new_ssl_connect"]
opaque Context.newSSLConnect: @& Context → IO BIO

namespace BIO

opaque AddrPointed : NonemptyType

/--
BIO Address type wrapper around all socket addresses used by OpenSSL.
-/
def Addr : Type := AddrPointed.type

instance : Nonempty Addr := AddrPointed.property

/-- Initialize an empty BIO
-/
@[extern "lean_bio_init"]
opaque init : IO BIO

namespace Addr

/--
Initialize an Addr struct with no information.
-/
@[extern "lean_bio_addr_init"]
opaque init : IO Addr

end Addr

/--
Write to BIO.
-/
@[extern "lean_bio_write"]
opaque write: @& BIO → @& ByteArray → IO Unit

/--
Read from connection.
-/
@[extern "lean_bio_read"]
opaque read: @& BIO → USize → IO (Bool × ByteArray)

/--
Get SSL from BIO.
-/
@[extern "lean_bio_get_ssl"]
opaque getSSL: BIO → IO SSL

/--
Set hostname and optionally the port.
-/
@[extern "lean_bio_set_conn_hostname"]
opaque setConnHostname: @& BIO → String → IO UInt32

def Socket := UInt32

/--
Open a socket.
-/
@[extern "lean_bio_socket"]
opaque socket : (domain : UInt32) → (socktype : UInt32) → (protocol : UInt32) → IO Socket

namespace Socket

/--
Connect a socket.
-/
@[extern "lean_bio_connect"]
opaque connect : (socket : Socket) → (addr : Addr) → IO UInt32

/--
Close a socket.
-/
@[extern "lean_bio_closesocket"]
opaque close : (socket : Socket) → IO UInt32

end Socket

/--
Start the connection.
-/
@[extern "lean_bio_do_connect"]
opaque doConnect : (bio : @& BIO) → IO UInt32


end BIO

end OpenSSL
