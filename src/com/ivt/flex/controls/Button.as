package com.ivt.flex.controls
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;

	import spark.components.Button;

	public class Button extends spark.components.Button
	{
		[Bindable]
		public var busy:Boolean = false;

		[Bindable]
		public var buttonDownPause:int = 1000; // 1 second by default

		private var _buttonDownTime:int = 0;

		public function Button()
		{
			super();
		}

		override protected function mouseEventHandler( event:Event ):void
		{
			var mouseEvent:MouseEvent = event as MouseEvent;

			if( event.type == MouseEvent.MOUSE_DOWN )
			{
				// How long since the last event?
				var time:int = getTimer();
				var downDiff:int = time - this._buttonDownTime;
				this._buttonDownTime = time;

				if( downDiff < this.buttonDownPause )
				{
					event.stopImmediatePropagation();
					if( mouseEvent )
					{
						mouseEvent.updateAfterEvent();
					}
					return;
				}
			}

			super.mouseEventHandler( event );
		}
	}
}
