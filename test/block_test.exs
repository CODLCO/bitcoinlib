defmodule BitcoinLib.BlockTest do
  use ExUnit.Case, async: true

  doctest BitcoinLib.Block

  alias BitcoinLib.Block

  test "decode block 55537, which is supposed to have two transactions" do
    block_data =
      "010000000939957c126b6ca4f4e471b125b0319ff54b09b5a298cc0941401312000000001f4709c4c8429eac5958a5203022bf9713f3931618790922adce7e057c7070427da5ea4b53ec131cbdb723000201000000010000000000000000000000000000000000000000000000000000000000000000ffffffff080453ec131c025d08ffffffff0100f2052a01000000434104c4fc99b3cdd691930d865388d247cb1c409c038db94947cfe9afd40c1871278a0fdfa9712005575ff08fa23b39537fef7963c472c0bcd73c5ef72018eb5dfd5aac0000000001000000030a845fbd460342e00c7a42cf880453f2b79485d874df854ca75d73b655799110000000008b48304502205aa5567931f33d7e3234b59fe7270cf1a4cc34ef5adc515dfaa226466067f2d8022100947d11f822755572016c0f7735e57ed6f6672a29364b126a47870b59935ecd2e014104d5ba87e0cac88d21765aa648fb25b9a11a834af1a01ceb525ac094ac930b9c4bf1b164f966a555d8d80f55f7022ebc4eb5ff5dc57a35729d2ca24fb1463244c3ffffffffb6836e979389a7da0f0ba92ca997cbc8d4a792fa74f802dc0420643dd12b52ca000000008c493046022100c5260c471a7a38b6470d4af2cb43a769e491cc2bc422fbff9b7e53b046d97c20022100d91c30be22ad860458de214bd9d3067ad42ef7d3f57077a48dc9186952cbcdc4014104a45cba41c8e2a0c6a7483ecbe9b97caa4c8426f68d53ab199afa6cb3ffa07224b3f2f2ff5ac6205948d6e64334f261fdf4c86e3c29af8d74aa749a943b2b545cffffffff45306d7d514528976b8f49c0e8b93904cde62f442335389a9f2d6936efe9222d000000008b48304502206137c983f49a89d943494866fd80b0102a46411255c65fdc270ce000b587cab7022100d56583d354bc8933f45b727895bb676e1d549e229aea7e03cdf8423db0f179f9014104bcac2a17441518d8e0dac8084973237a13728251646a88418c15e2178ddf238e924a1e473221beadacaa3875c726c78f8e02d80962a94bb5e451d52b5d80fbdbffffffff010070c9b28b0000001976a91414c1ed72d09150b8e5f49d94d53070d2c1f1db3688ac00000000"
      |> Binary.from_hex()

    {:ok, block} = Block.decode(block_data)

    assert Enum.count(block.transactions) == 2
  end

  test "decode block 39318 and make sure the transaction has 381 inputs" do
    filename = "#{__DIR__}/support/raw_blocks/block-39318.raw"
    {:ok, block_data} = File.read(filename)

    {:ok, %Block{transactions: [tx, _coinbase]}} = Block.decode(block_data)

    transaction_input_count = Enum.count(tx.inputs)

    assert transaction_input_count == 381
  end
end
