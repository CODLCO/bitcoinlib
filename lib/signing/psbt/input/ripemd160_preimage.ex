defmodule BitcoinLib.Signing.Psbt.Input.Ripemd160Preimage do
  defstruct [:hash, :value]

  alias BitcoinLib.Signing.Psbt.Input.Ripemd160Preimage
  alias BitcoinLib.Crypto

  def parse(<<preimage_hash::binary-size(20)>>, <<preimage::binary>>) do
    case validate(preimage_hash, preimage) do
      true ->
        %Ripemd160Preimage{
          hash: preimage_hash,
          value: preimage
        }

      false ->
        %{error: "RIPEMD160 preimage hash not matching hash in key"}
    end
  end

  def parse(_) do
    %{error: "invalid RIPEMD160 preimage format"}
  end

  defp validate(hash, preimage) do
    hash ==
      preimage
      |> Crypto.ripemd160()
  end
end