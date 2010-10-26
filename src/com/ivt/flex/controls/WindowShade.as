package com.ivt.flex.controls
{
	import flash.events.Event;
	import flash.events.MouseEvent;

	import spark.components.SkinnableContainer;
	import spark.components.supportClasses.ButtonBase;
	import spark.components.supportClasses.ToggleButtonBase;

	[Event(name="change", type="flash.events.Event")]

	[SkinState("open")]
	[SkinState("normalLeft")]
	[SkinState("openLeft")]
	[SkinState("disabledLeft")]
	[SkinState("normalRight")]
	[SkinState("openRight")]
	[SkinState("disabledRight")]

	public class WindowShade extends SkinnableContainer
	{
		public static const DIRECTION_DOWN:String = "down";
		public static const DIRECTION_LEFT:String = "left";
		public static const DIRECTION_RIGHT:String = "right";

		private var _open:Boolean = false;
		private var _label:String = "";
		private var _labelOpen:String;
		private var _duration:int = 300;
		private var _direction:String = DIRECTION_DOWN;
		private var _lockOpen:Boolean = false;

		[SkinPart(required="false")]
		public var button:ButtonBase;

		public function WindowShade()
		{
			super();
		}

		[Bindable]
		public function get open():Boolean
		{
			return this._open;
		}

		public function set open( value:Boolean ):void
		{
			if( this._open != value )
			{
				this._open = value;
				this.dispatchEvent( new Event( Event.CHANGE ) );
				this.updateButtonLock();
				this.invalidateSkinState();
			}
		}

		[Bindable]
		public function get label():String
		{
			return this._label;
		}

		public function set label( value:String ):void
		{
			this._label = value;
		}

		[Bindable]
		public function get labelOpen():String
		{
			return this._labelOpen;
		}

		public function set labelOpen( value:String ):void
		{
			this._labelOpen = value;
		}

		[Bindable]
		public function get duration():int
		{
			return this._duration;
		}

		public function set duration( value:int ):void
		{
			this._duration = value;
		}

		[Bindable]
		[Inspectable(defaultValue="down", enumeration="down,left,right")]
		public function get direction():String
		{
			return this._direction;
		}

		public function set direction( value:String ):void
		{
			this._direction = value;
		}

		[Bindable]
		public function get lockOpen():Boolean
		{
			return this._lockOpen;
		}

		public function set lockOpen( value:Boolean ):void
		{
			this._lockOpen = value;
			this.updateButtonLock();
		}

		override protected function partAdded( partName:String, instance:Object ):void
		{
			super.partAdded( partName, instance );
			if( instance == this.button )
			{
				this.button.label = this._label;
				this.button.addEventListener( MouseEvent.CLICK, this.onButtonClicked );
				this.updateButtonLock();
			}
		}

		override protected function partRemoved( partName:String, instance:Object ):void
		{
			if( instance == button )
			{
				this.button.removeEventListener( MouseEvent.CLICK, this.onButtonClicked );
			}

			super.partRemoved( partName, instance );
		}

		override protected function getCurrentSkinState():String
		{
			var state:String = super.getCurrentSkinState();
			if( this._open )
			{
				state = "open";
			}

			if( this._direction == DIRECTION_LEFT )
			{
				state += "Left";
			}
			else if( this._direction == DIRECTION_RIGHT )
			{
				state += "Right";
			}
			return state;
		}

		private function onButtonClicked( event:MouseEvent ):void
		{
			this.open = !this.open;
		}

		private function updateButtonLock():void
		{
			if( this.button )
			{
				if( this.button is ToggleButtonBase )
				{
					(this.button as ToggleButtonBase).selected = this._open;
				}
				this.button.enabled = !(this._open && this._lockOpen);
			}
		}
	}
}
