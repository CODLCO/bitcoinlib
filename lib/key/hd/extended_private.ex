defmodule BitcoinLib.Key.HD.ExtendedPrivate do
  @moduledoc """
  Bitcoin extended private key management module
  """

  @enforce_keys [:key, :chain_code]
  defstruct [:key, :chain_code, depth: 0, index: 0, parent_fingerprint: ""]

  @bitcoin_seed_hmac_key "Bitcoin seed"

  @private_key_length 32
  @version_bytes 0x0488ADE4

  alias BitcoinLib.Crypto
  alias BitcoinLib.Key.HD.{DerivationPath, ExtendedPrivate}
  alias BitcoinLib.Key.HD.DerivationPath.{Level}
  alias BitcoinLib.Key.HD.ExtendedPrivate.Derivation

  @doc """
  Converts a seed into a master private key hash containing the key itself and the chain code

  ## Examples
    iex> "7e4803bd0278e223532f5833d81605bedc5e16f39c49bdfff322ca83d444892ddb091969761ea406bee99d6ab613fad6a99a6d4beba66897b252f00c9dd7b364"
    ...> |> BitcoinLib.Key.HD.ExtendedPrivate.from_seed()
    %BitcoinLib.Key.HD.ExtendedPrivate{
      chain_code: 0x5A7AEBB0FBE37BB89E690A6E350FAFED353B624741269E71001E608732FD8125,
      key: 0x41DF6FA7F014A60FD79EC50B201FECF9CEDD8328921DDF670ACFCEF227242688
    }
  """
  @spec from_seed(String.t()) :: %ExtendedPrivate{}
  def from_seed(seed) do
    seed
    |> Base.decode16!(case: :lower)
    |> Crypto.hmac_bitstring(@bitcoin_seed_hmac_key)
    |> split
    |> to_struct
  end

  @doc """
  Serialization of a master private key into its xpriv version

  ## Examples
    values from https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#test-vector-1

    iex> %BitcoinLib.Key.HD.ExtendedPrivate {
    ...>   key: 0xE8F32E723DECF4051AEFAC8E2C93C9C5B214313817CDB01A1494B917C8436B35,
    ...>   chain_code: 0x873DFF81C02F525623FD1FE5167EAC3A55A049DE3D314BB42EE227FFED37D508
    ...> }
    ...> |> BitcoinLib.Key.HD.ExtendedPrivate.serialize_master_private_key()
    "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"
  """
  @spec serialize_master_private_key(%ExtendedPrivate{}) :: String.t()
  def serialize_master_private_key(%ExtendedPrivate{key: key, chain_code: chain_code}) do
    data = <<
      # "xprv"
      @version_bytes::size(32),
      # depth
      0::size(8),
      # index
      0::size(32),
      # parent's fingerprint
      0::size(32),
      # chain_code
      chain_code::size(256),
      # prepend of private key
      0::size(8),
      # private key
      key::size(256)
    >>

    <<
      data::bitstring,
      Crypto.checksum_bitstring(data)::bitstring
    >>
    |> Base58.encode()
  end

  @doc """
  Derives the nth child of a HD private key

  Takes a private key, its chain code and the child's index
  Returns the child's private key and it's associated chain code

  Inspired by https://learnmeabitcoin.com/technical/extended-keys#child-extended-key-derivation

  ## Examples

    iex> private_key = %BitcoinLib.Key.HD.ExtendedPrivate{
    ...>   key: 0xf79bb0d317b310b261a55a8ab393b4c8a1aba6fa4d08aef379caba502d5d67f9,
    ...>   chain_code: 0x463223aac10fb13f291a1bc76bc26003d98da661cb76df61e750c139826dea8b
    ...> }
    ...> index = 0
    ...> BitcoinLib.Key.HD.ExtendedPrivate.derive_child(private_key, index)
    {
      :ok,
      %BitcoinLib.Key.HD.ExtendedPrivate{
        key: 0x39f329fedba2a68e2a804fcd9aeea4104ace9080212a52ce8b52c1fb89850c72,
        chain_code: 0x05aae71d7c080474efaab01fa79e96f4c6cfe243237780b0df4bc36106228e31
      }
    }
  """
  @spec derive_child(%ExtendedPrivate{}, Integer.t(), Integer.t()) :: {:ok, %ExtendedPrivate{}}
  def derive_child(private_key, index, is_hardened \\ false) do
    Derivation.get_child(private_key, index, is_hardened)
  end

  @spec from_derivation_path(%ExtendedPrivate{}, %DerivationPath{}) :: {:ok, %ExtendedPrivate{}}
  def from_derivation_path(%ExtendedPrivate{} = private_key, %DerivationPath{} = derivation_path) do
    {child_private_key, _} =
      {private_key, derivation_path}
      |> maybe_derive_purpose
      |> maybe_derive_coin_type
      |> maybe_derive_account
      |> maybe_derive_change
      |> maybe_derive_address_index

    {:ok, child_private_key}
  end

  defp maybe_derive_purpose(
         {%ExtendedPrivate{} = private_key, %DerivationPath{purpose: nil} = derivation_path}
       ) do
    {private_key, derivation_path}
  end

  defp maybe_derive_purpose(
         {%ExtendedPrivate{} = private_key, %DerivationPath{purpose: purpose} = derivation_path}
       ) do
    {:ok, child_private_key} =
      case purpose do
        :bip44 -> derive_child(private_key, 44, true)
        _ -> {:ok, private_key}
      end

    {child_private_key, derivation_path}
  end

  defp maybe_derive_coin_type(
         {%ExtendedPrivate{} = private_key, %DerivationPath{coin_type: nil} = derivation_path}
       ) do
    {private_key, derivation_path}
  end

  defp maybe_derive_coin_type(
         {%ExtendedPrivate{} = private_key,
          %DerivationPath{coin_type: coin_type} = derivation_path}
       ) do
    {:ok, child_private_key} =
      case coin_type do
        :bitcoin -> derive_child(private_key, 0, true)
        :bitcoin_testnet -> derive_child(private_key, 1, true)
        _ -> {:ok, private_key}
      end

    {child_private_key, derivation_path}
  end

  defp maybe_derive_account({private_key, %DerivationPath{account: nil} = derivation_path}) do
    {private_key, derivation_path}
  end

  defp maybe_derive_account(
         {private_key,
          %DerivationPath{account: %Level{hardened?: true, value: account}} = derivation_path}
       ) do
    {:ok, child_private_key} = derive_child(private_key, account, true)

    {child_private_key, derivation_path}
  end

  defp maybe_derive_change({private_key, %DerivationPath{change: nil} = derivation_path}) do
    {private_key, derivation_path}
  end

  defp maybe_derive_change({private_key, %DerivationPath{change: change} = derivation_path}) do
    {:ok, child_private_key} =
      case change do
        :receiving_chain -> derive_child(private_key, 0, false)
        :change_chain -> derive_child(private_key, 1, false)
        _ -> {:ok, private_key}
      end

    {child_private_key, derivation_path}
  end

  defp maybe_derive_address_index(
         {private_key, %DerivationPath{address_index: nil} = derivation_path}
       ) do
    {private_key, derivation_path}
  end

  defp maybe_derive_address_index(
         {private_key,
          %DerivationPath{address_index: %Level{hardened?: false, value: index}} = derivation_path}
       ) do
    {:ok, child_private_key} = derive_child(private_key, index, true)

    {child_private_key, derivation_path}
  end

  defp split(extended_private_key) do
    <<private_key::binary-@private_key_length, chain_code::binary-@private_key_length>> =
      extended_private_key

    %{
      key: private_key,
      chain_code: chain_code
    }
  end

  defp to_struct(%{key: private_key, chain_code: chain_code}) do
    %ExtendedPrivate{
      key: Binary.to_integer(private_key),
      chain_code: Binary.to_integer(chain_code)
    }
  end
end
