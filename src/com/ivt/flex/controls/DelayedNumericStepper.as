package com.ivt.flex.controls
{
	
	import flash.events.*;
	import flash.utils.*;
	
	import spark.components.NumericStepper;

	/**
	 * Dispatched <code>Delay</code> milliseconds after the value changes.
	 */
	[Event(name="delayedChange", type="flash.events.Event")]
	
	/**
	 * Extends NumericStepper to prevent the CHANGE event being fired for a specified period of time.
	 */
	public class DelayedNumericStepper extends NumericStepper
	{

		public static const DELAYED_CHANGED:String = "delayedChange";

		/**
		 * The timer which keeps track of how long since the last key press.
		 * When it reaches a certain amount of time, *then* a change event is dispatched. 
		 */
		private var _timer:Timer = new Timer( 400, 1 );
		
		public function DelayedNumericStepper()
		{
		    this._timer.addEventListener
			(
				TimerEvent.TIMER_COMPLETE,
				function ( event:TimerEvent ):void { dispatchDelayedChange() }
			);

			this.addEventListener
			(
				FocusEvent.FOCUS_OUT,
				function ( event:FocusEvent ):void
				{
					_timer.stop();
					dispatchDelayedChange();
				}
			);

			this.addEventListener
			(
				Event.CHANGE,
				function ( event:Event ):void
				{
					_timer.reset();
					_timer.start();
				}
			);
		}

		/**
		 * Amount of milliseconds between the last keypress and a filter change event being
		 * dispatched. Defaults to 400.
		 */
		public function get delay():int { return this._timer.delay; }
		public function set delay( value:int ):void { this._timer.delay = value; }

		private function dispatchDelayedChange():void
		{
			dispatchEvent( new Event( DELAYED_CHANGED ) );
		}
	}
}