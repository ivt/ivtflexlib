package com.ivt.flex.controls
{
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;

	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.graphics.codec.PNGEncoder;

	[Event(name="change", type="flash.events.Event")]

	public class DrawingCanvas extends UIComponent
	{
		private var _drawing:Boolean;
		private var _startX:int;
		private var _startY:int;

		[Bindable]
		public var colour:uint;

		[Bindable]
		public var backgroundColour:uint;

		[Bindable]
		public var thickness:uint;

		private var _changed:Boolean = false;
		private var _modified:Boolean = false;

		public function DrawingCanvas()
		{
			super();

			this.colour = 0x000000;
			this.backgroundColour = 0xffffff;
			this.thickness = 1;

			this.addEventListener( MouseEvent.MOUSE_DOWN, this.onMouseDown );
			this.addEventListener( MouseEvent.MOUSE_UP, this.onMouseUp );
			this.addEventListener( MouseEvent.MOUSE_MOVE, this.onMouseMove );
			this.addEventListener( FlexEvent.CREATION_COMPLETE, this.onCreationComplete );
		}

		public function erase():void
		{
			this.graphics.clear();
			this.graphics.beginFill( this.backgroundColour, 1.0 );
			this.graphics.drawRect( 0, 0, super.width, super.height );
			this.graphics.endFill();
			this._modified = false;
		}

		public function load( data:ByteArray ):void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, this.onLoaded );
			loader.loadBytes( data );
			this._modified = true;
		}

		public function save():ByteArray
		{
			var bitmapData:BitmapData = new BitmapData( super.width, super.height );
			bitmapData.draw( this );
			return (new PNGEncoder()).encode( bitmapData );
		}

		public function get modified():Boolean
		{
			return this._modified;
		}

		protected function onCreationComplete( event:FlexEvent ):void
		{
			this.removeEventListener( FlexEvent.CREATION_COMPLETE, this.onCreationComplete );
			this.erase();
		}

		protected function onMouseDown( event:MouseEvent ):void
		{
			this._startX = super.mouseX;
			this._startY = super.mouseY;
			this._drawing = true;
		}

		protected function onMouseUp( event:MouseEvent ):void
		{
			this._drawing = false;
			if( this._changed )
			{
				this._changed = false;
				this._modified = true;
				this.dispatchEvent( new Event( Event.CHANGE ) );
			}
		}

		protected function onMouseMove( event:MouseEvent ):void
		{
			if( !event.buttonDown )
			{
				this._drawing = false;
			}

			if( this._drawing )
			{
				this.graphics.lineStyle( this.thickness, this.colour, 1.0, true, LineScaleMode.NORMAL, CapsStyle.ROUND,  JointStyle.ROUND );
				this.graphics.moveTo( this._startX, this._startY );
				this.graphics.lineTo( super.mouseX, super.mouseY );
				this._startX = super.mouseX;
				this._startY = super.mouseY;
				this._changed = true;
			}
		}

		protected function onLoaded( event:Event ):void
		{
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;
			if( loaderInfo )
			{
				var content:DisplayObject = loaderInfo.content;
				var bitmapData:BitmapData = new BitmapData( content.width, content.height );
				bitmapData.draw( content );
				this.graphics.beginBitmapFill( bitmapData );
				this.graphics.drawRect( 0, 0, bitmapData.width, bitmapData.height );
				this.graphics.endFill();
			}
		}
	}
}
