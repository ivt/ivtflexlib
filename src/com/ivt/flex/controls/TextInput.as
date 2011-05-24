package com.ivt.flex.controls
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import mx.controls.listClasses.BaseListData;
	import mx.controls.listClasses.IDropInListItemRenderer;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.events.FlexEvent;
	import mx.states.State;

	import spark.components.TextInput;

	/**
	 * Dispatched <code>Delay</code> milliseconds after the text changes.
	 */
	[Event(name="delayedChange", type="flash.events.Event")]

	/**
	 * This TextInput enhances the spark TextInput with a number of new features.
	 * All of them are optional, so if just used without specifying any details, it should act the same as a regular TextInput.
	 *  - Focused skin state
	 *  - Text prompt
	 *  - Text prefix (useful for displaying currency for example)
	 *  - Drop-in ItemRenderer support
	 */
	public class TextInput extends spark.components.TextInput implements IListItemRenderer, IDropInListItemRenderer
	{
		[SkinState("focused")]

		public static const DELAYED_CHANGED:String = "delayedChange";

		private var _isFocused:Boolean;
		private var _prefix:String = '';
		private var _text:String = '';
		private var _timer:Timer = new Timer( 0, 1 );

		public function TextInput()
		{
			super();

			this._timer.addEventListener( TimerEvent.TIMER_COMPLETE, this.onTimerDone );
			this.addEventListener
			(
				Event.CHANGE,
				function ( event:Event ):void
				{
					if( _timer.delay > 0 )
					{
						_timer.reset();
						_timer.start();
					}
				}
			);
		}

		override protected function partAdded( partName:String, instance:Object ):void
		{
			super.partAdded( partName, instance );
			if( instance == this.textDisplay )
			{
				this.textDisplay.addEventListener( FocusEvent.FOCUS_OUT, this.onFocusOutHandler );
			}
		}

		override protected function partRemoved( partName:String, instance:Object ):void
		{
			super.partRemoved( partName, instance );
			if( instance == this.textDisplay )
			{
				this.textDisplay.removeEventListener( FocusEvent.FOCUS_OUT, this.onFocusOutHandler );
			}
		}

		private function onFocusOutHandler( event:FocusEvent ):void
		{
			this._isFocused = false;
			this._text = super.text;
			super.text = this._prefix + this._text;
			this.invalidateSkinState();

			if( this._timer.running )
			{
				this._timer.stop();
				this.onTimerDone( null );
			}
		}

		override protected function getCurrentSkinState():String
		{
			if( this._isFocused && this.skin )
			{
				for each ( var state:State in this.skin.states )
				{
					if ( state.name == "focused" )
					{
						return "focused";
					}
				}
			}

			return super.getCurrentSkinState();
		}

		/**
		 * The text which is displayed before the text when it does not have focus.
		 */
		public function get prefix():String { return this._prefix }
		public function set prefix( value:String ):void
		{
			this._prefix = value;
		}

		[Bindable]
		override public function get text():String
		{
			return this._isFocused ? super.text : this._text;
		}

		// Seem to need these or else the data binding in the sub class will not work...
		[Bindable("change")]
		[Bindable("textChanged")]

		/**
		 * Automatically sets the _prompting property to false, so BE CAREFUL!
		 * If you need to set the prompt text from within this class, ALWAYS USE super.text!
		 * That will bypass this, and prevent setting prompting flag to false.
		 * @param value
		 */
		override public function set text( value:String ):void
		{
			this._text = value;
		}


		/**
		 * Amount of milliseconds between the last key press and a filter change event being
		 * dispatched. Defaults to 0.
		 */
		public function get delay():int { return this._timer.delay; }
		public function set delay( value:int ):void { this._timer.delay = value; }

		/**
		 * Listener for when the timer is finished. Dispatches a delayedChange event.
		 */
		private function onTimerDone( event:TimerEvent ):void
		{
			this.dispatchEvent( new Event( DELAYED_CHANGED ) );
		}

		// =============================================================================================================
		//      The properties required to use this as a drop in item renderer/editor... Copied from halo TextInput
		// =============================================================================================================

		private var _data:Object;

		public function get data():Object
		{
			return null;
		}

		public function set data( value:Object ):void
		{
			this._data = value;

			var newText:*;
			if ( this._listData )
			{
				newText = this._listData.label;
			}
			else if ( this._data != null )
			{
				if ( this._data is String )
					newText = String( this._data );
				else
					newText = this._data.toString();
			}

			if ( newText !== undefined )
			{
				text = newText;
			}

			dispatchEvent( new FlexEvent( FlexEvent.DATA_CHANGE ) );
		}


		private var _listData:BaseListData;

		[Bindable("dataChange")]
		[Inspectable(environment="none")]

		public function get listData():BaseListData
		{
			return this._listData;
		}

		public function set listData( value:BaseListData ):void
		{
			this._listData = value;
		}
	}
}
