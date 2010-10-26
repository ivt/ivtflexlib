package com.ivt.flex.utils
{
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;

	/**
	 * Adapted from: http://blog.earthbrowser.com/2009/01/simple-solution-for-mousewheel-events.html
	 *
	 * For some reason when using wmode="opaque|transparent" mouse wheel events no longer work, and using
	 * ExternalMouseWheel fixes that problem by passing mouse wheel events from the browser into the flash
	 * application.
	 *
	 * Usage:  ExternalMouseWheel.init( FlexGlobals.topLevelApplication as DisplayObject );
	 */

	public class ExternalMouseWheel
	{
		static private var _initialised:Boolean = false;
		static private var _object:InteractiveObject;
		static private var _event:MouseEvent;

		static public function init( displayObject:DisplayObject ):void
		{
			if( !_initialised )
			{
				_initialised = true;

				displayObject.addEventListener(
						MouseEvent.MOUSE_MOVE,
						function( event:MouseEvent ):void
						{
							_object = InteractiveObject( event.target );
							_event = MouseEvent( event );
						} );

				if( ExternalInterface.available )
				{
					var id:String = 'ivtmw_' + Math.floor( Math.random() * 1000000 );
					ExternalInterface.addCallback( id, function():void{} );
					ExternalInterface.call( _JAVASCRIPT );
					ExternalInterface.call( "ivtmw.init", id );
					ExternalInterface.addCallback( 'externalMouseEvent', onExternalMouseEvent );
				}
			}
		}

		static private function onExternalMouseEvent( delta:Number ):void
		{
			if( _object && _event )
			{
				_object.dispatchEvent( new MouseEvent( MouseEvent.MOUSE_WHEEL, true, false, _event.localX, _event.localY, _event.relatedObject, _event.ctrlKey, _event.altKey, _event.shiftKey, _event.buttonDown, int( delta ) ) );
			}
		}

		static private const _JAVASCRIPT:XML =
			<script>
				<![CDATA[
					function()
					{
						// Create unique namespace
						if( typeof ivtmw == "undefined" || !ivtmw )
						{
							ivtmw = {};
						}

						ivtmw.findSwf = function( id )
						{
							var ii = 0;
							var objects = document.getElementsByTagName( "object" );
							for( ii = 0; ii < objects.length; ii++ )
							{
								if( typeof objects[ ii ][ id ] != "undefined" )
								{
									return objects[ ii ];
								}
							}

							var embeds = document.getElementsByTagName( "embed" );
							for( ii = 0; ii < embeds.length; ii++ )
							{
								if( typeof embeds[ ii ][ id ] != "undefined" )
								{
									return embeds[ ii ];
								}
							}
						}

						ivtmw.init = function( id )
						{
							var swf = ivtmw.findSwf( id );
							if( swf )
							{
								var mouseOver = false;
								var userAgent = navigator.userAgent.toLowerCase();
								var browserIsOpera = /opera/.test(userAgent);

								// Mouse move detection for mouse wheel support
								function mouseMove( event )
								{
									mouseOver = event && event.target && (event.target == swf);
								}

								// Mouse wheel support
								var mouseWheel = function( event )
								{
									if( mouseOver )
									{
										var delta = 0;
										if( event.wheelDelta )
										{
											delta = event.wheelDelta / (browserIsOpera ? 12 : 120);
										}
										else if( event.detail )
										{
											delta = -event.detail;
										}

										if( event.preventDefault )
										{
											event.preventDefault();
										}

										swf.externalMouseEvent( delta );
										return true;
									}

									return false;
								}

								// Install mouse listeners
								if( typeof window.addEventListener != 'undefined' )
								{
									window.addEventListener( 'DOMMouseScroll', mouseWheel, false );
									window.addEventListener( 'DOMMouseMove', mouseMove, false );
								}

								window.onmousewheel = document.onmousewheel = mouseWheel;
								window.onmousemove = document.onmousemove = mouseMove;
							}
						}
					}
				]]>
			</script>;
	}
}