const { expectRevert } = require('@openzeppelin/test-helpers');
const ChiliToken = artifacts.require('ChiliToken');

contract('ChiliToken', ([alice, bob, carol]) => {
    beforeEach(async () => {
        this.chili = await ChiliToken.new({ from: alice });
    });

    it('should have correct name and symbol and decimal', async () => {
        const name = await this.chili.name();
        const symbol = await this.chili.symbol();
        const decimals = await this.chili.decimals();
        assert.equal(name.valueOf(), 'ChiliToken');
        assert.equal(symbol.valueOf(), 'SUSHI');
        assert.equal(decimals.valueOf(), '18');
    });

    it('should only allow owner to mint token', async () => {
        await this.chili.mint(alice, '100', { from: alice });
        await this.chili.mint(bob, '1000', { from: alice });
        await expectRevert(
            this.chili.mint(carol, '1000', { from: bob }),
            'Ownable: caller is not the owner',
        );
        const totalSupply = await this.chili.totalSupply();
        const aliceBal = await this.chili.balanceOf(alice);
        const bobBal = await this.chili.balanceOf(bob);
        const carolBal = await this.chili.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '100');
        assert.equal(bobBal.valueOf(), '1000');
        assert.equal(carolBal.valueOf(), '0');
    });

    it('should supply token transfers properly', async () => {
        await this.chili.mint(alice, '100', { from: alice });
        await this.chili.mint(bob, '1000', { from: alice });
        await this.chili.transfer(carol, '10', { from: alice });
        await this.chili.transfer(carol, '100', { from: bob });
        const totalSupply = await this.chili.totalSupply();
        const aliceBal = await this.chili.balanceOf(alice);
        const bobBal = await this.chili.balanceOf(bob);
        const carolBal = await this.chili.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '90');
        assert.equal(bobBal.valueOf(), '900');
        assert.equal(carolBal.valueOf(), '110');
    });

    it('should fail if you try to do bad transfers', async () => {
        await this.chili.mint(alice, '100', { from: alice });
        await expectRevert(
            this.chili.transfer(carol, '110', { from: alice }),
            'ERC20: transfer amount exceeds balance',
        );
        await expectRevert(
            this.chili.transfer(carol, '1', { from: bob }),
            'ERC20: transfer amount exceeds balance',
        );
    });
  });
