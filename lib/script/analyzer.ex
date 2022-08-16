defmodule BitcoinLib.Script.Analyzer do
  alias BitcoinLib.Script.Opcodes.{BitwiseLogic, Crypto, Stack}

  @pub_key_hash_size 20
  @uncompressed_pub_key_size 65

  @dup Stack.Dup.v()
  @equal BitwiseLogic.Equal.v()
  @equal_verify BitwiseLogic.EqualVerify.v()
  @hash160 Crypto.Hash160.v()
  @check_sig Crypto.CheckSig.v()

  # 41 <<_pub_key::520>> ac
  def identify(<<@uncompressed_pub_key_size::8, _pub_key::bitstring-520, @check_sig::8>>),
    do: :p2pk

  # 76 a9 14 <<_pub_key_hash::160>> 88 ac
  def identify(
        <<@dup::8, @hash160::8, @pub_key_hash_size::8, _pub_key_hash::bitstring-160,
          @equal_verify::8, @check_sig::8>>
      ),
      do: :p2pkh

  # a9 14 <<_script_hash::160>> 87
  def identify(<<@hash160, @pub_key_hash_size, _script_hash::bitstring-160, @equal>>), do: :p2sh

  def identify(script) when is_bitstring(script), do: :unknown
end
