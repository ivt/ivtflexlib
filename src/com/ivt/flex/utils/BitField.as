package com.ivt.flex.utils
{
	public class BitField
	{
		private var _bits:uint;

		public function BitField( value:uint = 0 )
		{
			this._bits = value;
		}

		[Bindable]
		public function get bits():uint
		{
			return this._bits;
		}

		public function set bits( value:uint ):void
		{
			this._bits = value;
		}

		public function getBit( bit:uint ):Boolean
		{
			return (this.bits & (1 << bit)) == (1 << bit);
		}

		public function setBit( bit:uint, high:Boolean = true ):void
		{
			if( high )
			{
				this.bits |= (1 << bit);
			}
			else
			{
				this.bits &= ~(1 << bit);
			}
		}
	}
}
