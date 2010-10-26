package com.ivt.flex.controls
{
	import flash.events.EventDispatcher;

	import mx.core.IMXMLObject;

	import spark.components.CheckBox;

	public class CheckBoxGroup extends EventDispatcher implements IMXMLObject
	{
		private var _checkBoxes:Array;
		public var id:String;

		public function CheckBoxGroup()
		{
			super();
		}

		public function get numCheckBoxes():int
		{
			return this._checkBoxes.length;
		}

		public function getCheckBoxAt( index:int ):CheckBox
		{
			if( index >= 0 && index < this.numCheckBoxes )
			{
				return this._checkBoxes[ index ];
			}

			return null;
		}

		public function set checkBoxes( value:Array ):void
		{
			this._checkBoxes = [];

			for each( var object:Object in value )
			{
				if( object is CheckBox )
				{
					this._checkBoxes.push( object );
				}
			}
		}

		// The CheckBoxes are treated as bits
		public function get selectedValue():uint
		{
			var value:uint = 0;

			if( this._checkBoxes )
			{
				for( var ii:int = 0; ii < this._checkBoxes.length; ii++ )
				{
					if( this._checkBoxes[ ii ].selected )
					{
						value |= (1 << ii);
					}
				}
			}

			return value;
		}

		public function set selectedValue( value:uint ):void
		{
			for( var ii:int = 0; ii < this._checkBoxes.length; ii++ )
			{
				this._checkBoxes[ ii ].selected = (value & (1 << ii)) > 0;
			}
		}

		public function initialized( document:Object, id:String ):void
		{
			this.id = id;
		}
	}
}
