
namespace OpenSSL

/-
Initialize the OpenSSL library.
-/
@[extern "lean_ssl_lib_init"]
constant initLib: Unit → IO Unit

constant ContextPointed : PointedType

def Context : Type := ContextPointed.type

instance : Inhabited Context := ⟨ContextPointed.val⟩

/-
Initialize a SSL context.
-/
@[extern "lean_ssl_ctx_init"]
constant Context.init : Unit → IO Context

/-
Use certificate file for SSL Context.
-/
@[extern "lean_ssl_ctx_use_certificate_file"]
constant Context.useCertificateFile : @& Context → @& String → IO Bool

/-
Use private key file for SSL Context.
-/
@[extern "lean_ssl_ctx_use_private_key_file"]
constant Context.usePrivateKeyFile : @& Context → @& String → IO Bool

/-
Check private key for SSL Context assuming it has been loaded.
-/
@[extern "lean_ssl_ctx_check_private_key"]
constant Context.checkPrivateKey : @& Context → @& String → IO Bool

constant SSLPointed : PointedType

def SSL : Type := SSLPointed.type

instance : Inhabited SSL := ⟨SSLPointed.val⟩

/-
Initialize a SSL struct.
-/
@[extern "lean_ssl_init"]
constant Context.initSSL : @& Context → IO SSL

namespace SSL

inductive Status
  | ok
  | wantIO
  | fail
  deriving BEq, Hashable

/-
SSL_is_init_finished() returns 1 if the SSL/TLS connection
is in a state where fully protected application data can be transferred or 0 otherwise.
-/
@[extern "lean_ssl_is_init_finished"]
constant isInitFinished: @& SSL → IO Bool

/-
Is the SSL connection set to be used as a server.
-/
@[extern "lean_ssl_is_server"]
constant isServer: @& SSL → IO Bool

/-
Use as a server.
-/
@[extern "lean_ssl_set_accept_state"]
constant setAcceptState: @& SSL → IO Unit

/-
Use as a client.
-/
@[extern "lean_ssl_set_connect_state"]
constant setConnectState: @& SSL → IO Unit

/-
Write to connection.
-/
@[extern "lean_ssl_write"]
constant write: @& SSL → @& ByteArray → IO Unit

/-
Read from connection.
-/
@[extern "lean_ssl_read"]
constant read: @& SSL → USize → IO (Bool × ByteArray)

/-
Get error.
-/
@[extern "lean_ssl_get_error"]
constant getError: @& SSL → UInt32 → IO UInt32

end SSL

-- BIO

constant BIOPointed : PointedType

/-
Binary IO buffer
-/
def BIO : Type := BIOPointed.type

instance : Inhabited BIO := ⟨BIOPointed.val⟩

/-
Set read BIO
-/
@[extern "lean_ssl_set_rbio"]
constant SSL.setReadBIO : @& SSL → @& BIO → IO Unit

/-
Set write BIO
-/
@[extern "lean_ssl_set_wbio"]
constant SSL.setWriteBIO : @& SSL → @& BIO → IO Unit

namespace BIO

/-
Initialize a BIO struct.
-/
@[extern "lean_bio_init"]
constant init : Unit → IO BIO

/-
Write to BIO.
-/
@[extern "lean_bio_write"]
constant write: @& BIO → @& ByteArray → IO Unit

/-
Read from connection.
-/
@[extern "lean_bio_read"]
constant read: @& BIO → USize → IO (Bool × ByteArray)


end BIO

end OpenSSL
