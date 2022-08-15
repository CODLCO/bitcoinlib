defmodule BitcoinLib.Key.PublicHash do
  @moduledoc """
  Bitcoin Public Key Hash module
  """

  alias BitcoinLib.Crypto

  @doc """
  Extract a public key hash from a bitcoin public key

  Inspired by https://learnmeabitcoin.com/technical/public-key-hash

  ## Examples
    iex> <<0x02b4632d08485ff1df2db55b9dafd23347d1c47a457072a1e87be26896549a8737::264>>
    ...> |> BitcoinLib.Key.PublicHash.from_public_key()
    <<0x93ce48570b55c42c2af816aeaba06cfee1224fae::160>>
  """
  @spec from_public_key(bitstring()) :: integer()
  def from_public_key(public_key) do
    public_key
    |> Crypto.hash160_bitstring()
  end
end
