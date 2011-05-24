package com.ivt.flex.events
{

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FocusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	/**
	 * This class can be attached to any listener, and will delay the dispatching of an event for a specified time.
	 * This is useful for several things, such as scrolling a list with the keyboard, where you don't care about
	 * every change, only the last one.
	 * Also, if you have a text input which filters something by going all the way to the server, you don't need
	 * to go for each keystroke, rather just the final one.
	 */
	public class DelayedEventListener extends EventDispatcher
	{

		public function get source():IEventDispatcher { return this._source; }
		public function get eventType():String { return this._eventType; }
		public function get delay():Number { return this._delay; }

		private var _source:IEventDispatcher;
		private var _eventType:String;
		private var _delay:Number;
		private var _lastEvents:Object = new Object();

		/**
		 * The timer which keeps track of how long since the last event.
		 * When it reaches a certain amount of time, *then* the event is dispatched.
		 */
		private var _timer:Timer;

		public function DelayedEventListener( source:IEventDispatcher, delay:Number = 400 )
		{
			this._source = source;
			this._eventType = eventType;
			this._delay = delay;

			this._timer = new Timer( this._delay, 1 );
		    this._timer.addEventListener( TimerEvent.TIMER_COMPLETE, this.dispatchDelayedEvents );

			if ( this._source != null )
			{
				// The event may not support focus out, but it is a good bet it will, and this shouldn't cause breakage
				// even if it doesn't...
				this._source.addEventListener( FocusEvent.FOCUS_OUT, this.onFocusOut );
			}
		}

		public override function addEventListener( type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, weakReference:Boolean = false ):void
		{
			super.addEventListener( type, listener, useCapture, priority, weakReference );
			this._source.addEventListener( type,  this.onEvent );
		}

		private function onFocusOut( event:FocusEvent ):void
		{
			this._timer.stop();
			this.dispatchDelayedEvents();
		}

		private function onEvent( event:Event ):void
		{
			// Overwrite any existing events of this type. We are only interested in the most recent...
			this._lastEvents[ event.type ] = event;
			_timer.reset();
			_timer.start();
		}

		private function dispatchDelayedEvents( trigger:Event = null ):void
		{
			for ( var type:String in this._lastEvents )
			{
				this.dispatchEvent( this._lastEvents[ type ] );
			}
			this._lastEvents = new Object();
		}
	}
}
