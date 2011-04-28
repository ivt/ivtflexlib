package com.ivt.flex.layouts
{
	import flash.geom.Rectangle;

	import mx.core.ILayoutElement;
	import mx.core.IVisualElement;

	import spark.components.supportClasses.GroupBase;
	import spark.core.NavigationUnit;
	import spark.layouts.supportClasses.DropLocation;
	import spark.layouts.supportClasses.LayoutBase;

	// TODO
	// FlowLayout doesn't support virtual layout other than to get the elements using the correct function.
	// What it needs to do is figure out which elements are in view and only handle those.

	public class FlowLayout extends LayoutBase
	{
		private var _horizontalGap:Number = 6;
		private var _verticalGap:Number = 6;
		private var _verticalAlign:String = "top";
		private var _horizontalAlign:String = "left";
		private var _paddingLeft:Number = 0;
		private var _paddingRight:Number = 0;
		private var _paddingTop:Number = 0;
		private var _paddingBottom:Number = 0;
		private var _lastElementBottomRight:Object = { x:0, y:0 };

		public function FlowLayout()
		{
			super();
		}

		[Inspectable(category="General")]

		public function get horizontalGap():int
		{
			return this._horizontalGap;
		}

		public function set horizontalGap( value:int ):void
		{
			if( this._horizontalGap == value )
			{
				return;
			}

			this._horizontalGap = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		[Inspectable(category="General")]

		public function get verticalGap():int
		{
			return this._verticalGap;
		}

		public function set verticalGap( value:int ):void
		{
			if( this._verticalGap == value )
			{
				return;
			}

			this._verticalGap = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		public function set gap( value:int ):void
		{
			if( this._horizontalGap == value && this._verticalGap == value )
			{
				return;
			}

			this._horizontalGap = value;
			this._verticalGap = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		[Inspectable(category="General", enumeration="top,bottom,middle,contentJustify", defaultValue="top")]

		public function get verticalAlign():String
		{
			return this._verticalAlign;
		}

		public function set verticalAlign(value:String):void
		{
			if( value == this._verticalAlign )
			{
				return;
			}

			this._verticalAlign = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		[Inspectable(category="General", enumeration="left,right,center,justify", defaultValue="left")]

		public function get horizontalAlign():String
		{
			return this._horizontalAlign;
		}

		public function set horizontalAlign(value:String):void
		{
			if( value == this._horizontalAlign )
			{
				return;
			}

			this._horizontalAlign = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		[Inspectable(category="General")]

		public function get paddingLeft():Number
		{
			return this._paddingLeft;
		}

		public function set paddingLeft( value:Number ):void
		{
			if( this._paddingLeft == value )
			{
				return;
			}

			this._paddingLeft = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		[Inspectable(category="General")]

		public function get paddingRight():Number
		{
			return this._paddingRight;
		}

		public function set paddingRight( value:Number ):void
		{
			if( this._paddingRight == value )
			{
				return;
			}

			this._paddingRight = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		[Inspectable(category="General")]

		public function get paddingTop():Number
		{
			return this._paddingTop;
		}

		public function set paddingTop( value:Number ):void
		{
			if( this._paddingTop == value )
			{
				return;
			}

			this._paddingTop = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		[Inspectable(category="General")]

		public function get paddingBottom():Number
		{
			return this._paddingBottom;
		}

		public function set paddingBottom( value:Number ):void
		{
			if( this._paddingBottom == value )
			{
				return;
			}

			this._paddingBottom = value;

			var layoutTarget:GroupBase = this.target;
			if( layoutTarget )
			{
				layoutTarget.invalidateDisplayList();
			}
		}

		public function getLastElementBottomRight():Object
		{
			return this._lastElementBottomRight;
		}

		override public function measure():void
		{
			super.measure();

			var layoutTarget:GroupBase = this.target;
			if( !layoutTarget )
			{
				return;
			}

			// ** Being Tricky **
			// Create a function variable and assign the appropriate function to it.
			// Saves having to have two almost identical methods to handle layout.
			var getElementAt:Function;
			if( this.useVirtualLayout )
			{
				getElementAt = layoutTarget.getVirtualElementAt
			}
			else
			{
				getElementAt = layoutTarget.getElementAt
			}

			var width:Number = layoutTarget.width;
			if( layoutTarget.explicitWidth )
			{
				width = layoutTarget.explicitWidth;
			}
			else if( layoutTarget.percentWidth )
			{
				width = Math.min( layoutTarget.getMaxBoundsWidth(), Math.max( layoutTarget.getMinBoundsWidth(), Math.round( layoutTarget.percentWidth * 0.01 * layoutTarget.width ) ) );
			}

			var x:Number = 0;
			var y:Number = 0;
			var maxWidth:Number = 0;
			var maxHeight:Number = 0;
			var elementWidth:Number = 0;
			var elementHeight:Number = 0;
			var count:uint = layoutTarget.numElements;

			for( var ii:int = 0; ii < count; ii++ )
			{
				var element:ILayoutElement = getElementAt( ii );
				if( null == element )
				{
					element = this.typicalLayoutElement;
				}

				if( element )
				{
					elementWidth = Math.ceil( element.getPreferredBoundsWidth() );
					elementHeight = Math.ceil( element.getPreferredBoundsHeight() );

					if( x + elementWidth > width && x > 0 )
					{
						x = 0;
						y += elementHeight + this._verticalGap;
					}

					maxWidth = Math.max( maxWidth, x + elementWidth );
            		maxHeight = Math.max( maxHeight, y + elementHeight );

					x += elementWidth + this._horizontalGap;
				}
			}

			var hPadding:Number = this._paddingLeft + this._paddingRight;
            var vPadding:Number = this._paddingTop + this._paddingBottom;

			layoutTarget.measuredWidth = maxWidth + hPadding;
			layoutTarget.measuredHeight = maxHeight + vPadding;
			layoutTarget.measuredMinWidth = maxWidth + hPadding;
			layoutTarget.measuredMinHeight = maxHeight + vPadding;
		}

		override public function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );

			var layoutTarget:GroupBase = this.target;
			if( !layoutTarget )
			{
				return;
			}

			// ** Being Tricky **
			// Create a function variable and assign the appropriate function to it.
			// Saves having to have two almost identical methods to handle layout.
			var getElementAt:Function;
			if( this.useVirtualLayout )
			{
				getElementAt = layoutTarget.getVirtualElementAt
			}
			else
			{
				getElementAt = layoutTarget.getElementAt
			}

			var targetWidth:Number = Math.max(0, width - this._paddingLeft - this._paddingRight );
			var x:Number = 0;
			var y:Number = this._paddingTop;
			var row:int = 0;
			var rowWidth:Array = [ 0 ];
			var rowHeight:Array = [ 0 ];
			var rowCount:Array = [ 0 ];
			var maxWidth:Number = 0;
			var maxHeight:Number = this._paddingTop;
			var elementWidth:Number = 0;
			var elementHeight:Number = 0;
			var count:uint = layoutTarget.numElements;

			// First pass: Compute element x,y and row heights
			for( var ii:int = 0; ii < count; ii++ )
			{
				var element:ILayoutElement = getElementAt( ii );
				if( element && element.includeInLayout )
				{
					element.setLayoutBoundsSize( NaN, NaN );

					elementWidth = element.getLayoutBoundsWidth();
					elementHeight = element.getLayoutBoundsHeight();

					if( x + elementWidth > targetWidth && x > 0 )
					{
						x = 0;
						y += rowHeight[ row ] + this._verticalGap;
						rowWidth.push( 0 );
						rowHeight.push( elementHeight );
						rowCount.push( 0 );
						row++;
					}

					element.setLayoutBoundsPosition( x + this._paddingLeft, y );

					rowWidth[ row ] = x + elementWidth;
					rowHeight[ row ] = Math.max( rowHeight[ row ], elementHeight );
					rowCount[ row ]++;
					maxWidth = Math.max( maxWidth, x + elementWidth );
            		maxHeight = Math.max( maxHeight, y + elementHeight );

					x += elementWidth + this._horizontalGap;
				}
			}

			this._lastElementBottomRight.x = x - this._horizontalGap;
			this._lastElementBottomRight.y = y + rowHeight[ row ];
			layoutTarget.setContentSize( maxWidth + this._paddingRight, maxHeight + this._paddingBottom );

			// Second pass: if necessary, fix up height values based on the updated contentHeight
			if( this._verticalAlign != "top" )
			{
				x = 0;
				row = 0;
				for( ii = 0; ii < count; ii++ )
				{
					element = getElementAt( ii );
					if( element && element.includeInLayout )
					{
						elementWidth = element.getLayoutBoundsWidth();

						x += elementWidth;
						if( x > targetWidth )
						{
							x = elementWidth + this._horizontalGap;
							row++;
						}

						switch( this._verticalAlign )
						{
							case "contentJustify":
								element.setLayoutBoundsSize( elementWidth, rowHeight[ row ] );
								break;

							case "middle":
								element.setLayoutBoundsPosition( element.getLayoutBoundsX(), element.getLayoutBoundsY() + ( rowHeight[ row ] - element.getLayoutBoundsHeight() ) / 2 );
								break;

							case "bottom":
								element.setLayoutBoundsPosition( element.getLayoutBoundsX(), element.getLayoutBoundsY() + ( rowHeight[ row ] - element.getLayoutBoundsHeight() ) );
								break;
						}
					}
				}
			}

			// Third pass: if necessary, fix up width values based on the updated contentWidth
			if( this._horizontalAlign != "left" )
			{
				x = 0;
				row = 0;
				var remain:Number = targetWidth - rowWidth[ row ];
				var portion:Number = ( rowCount[ row ] > 0 ) ? remain / rowCount[ row ] : 0;
				var offset:Number = 0;
				for( ii = 0; ii < count; ii++ )
				{
					element = getElementAt( ii );
					if( element && element.includeInLayout )
					{
						elementWidth = element.getLayoutBoundsWidth();
						elementHeight = element.getLayoutBoundsHeight();

						x += elementWidth;
						if( x > targetWidth )
						{
							x = elementWidth + this._horizontalGap;
							row++;
							remain = targetWidth - rowWidth[ row ];
							portion = ( rowCount[ row ] > 0 ) ? remain / rowCount[ row ] : 0;
							offset = 0;
						}

						switch( this._horizontalAlign )
						{
							case "justify":
								element.setLayoutBoundsPosition( element.getLayoutBoundsX() + offset, element.getLayoutBoundsY() );
								element.setLayoutBoundsSize( elementWidth + portion, elementHeight );
								offset += portion;
								break;

							case "center":
								element.setLayoutBoundsPosition( element.getLayoutBoundsX() + ( remain / 2 ), element.getLayoutBoundsY() );
								break;

							case "right":
								element.setLayoutBoundsPosition( element.getLayoutBoundsX() + remain, element.getLayoutBoundsY() );
								break;
						}
					}
				}
			}
		}

		override public function getNavigationDestinationIndex( currentIndex:int, navigationUnit:uint, arrowKeysWrapFocus:Boolean ):int
		{
			if( !this.target || this.target.numElements < 1 )
			{
				return -1;
			}

			var maxIndex:int = this.target.numElements - 1;

			// Special case when nothing was previously selected
			if( currentIndex == -1 )
			{
				if( navigationUnit == NavigationUnit.UP || navigationUnit == NavigationUnit.LEFT )
				{
					return arrowKeysWrapFocus ? maxIndex : -1;
				}

				if( navigationUnit == NavigationUnit.DOWN || navigationUnit == NavigationUnit.RIGHT )
				{
					return 0;
				}
			}

			// Make sure currentIndex is within range
			currentIndex = Math.max( 0, Math.min( maxIndex, currentIndex ) );

			var newIndex:int;

			switch( navigationUnit )
			{
				case NavigationUnit.LEFT:
				{
					if( arrowKeysWrapFocus && currentIndex == 0 )
					{
						newIndex = maxIndex;
					}
					else
					{
						newIndex = currentIndex - 1;
					}
					break;
				}
				case NavigationUnit.RIGHT:
				{
					if( arrowKeysWrapFocus && currentIndex == 0 )
					{
						newIndex = 0;
					}
					else
					{
						newIndex = currentIndex + 1;
					}
					break;
				}
				case NavigationUnit.UP:
				{
					var element:ILayoutElement = this.target.getElementAt( currentIndex );
					var height:Number = element.getLayoutBoundsHeight() / 2;
					var y:Number = element.getLayoutBoundsY() - this._verticalGap;
					var half:Number = element.getLayoutBoundsX() + ( element.getLayoutBoundsWidth() / 2 );
					if( y >= 0 )
					{
						do
						{
							y -= height;
							newIndex = this.calculateDropOverIndex( half, y );
						} while( newIndex == currentIndex && y >= 0 );
					}
					else
					{
						newIndex = currentIndex;
					}
					break;
				}
				case NavigationUnit.DOWN:
				{
					element = this.target.getElementAt( currentIndex );
					height = element.getLayoutBoundsHeight() / 2;
					y = element.getLayoutBoundsY() + ( height * 2 ) + this._verticalGap;
					half = element.getLayoutBoundsX() + ( element.getLayoutBoundsWidth() / 2 );
					if( y <= this.target.height )
					{
						do
						{
							y += height;
							newIndex = this.calculateDropOverIndex( half, y );
						} while( newIndex == currentIndex && y <= this.target.height );
					}
					else
					{
						newIndex = currentIndex;
					}
					break;
				}
				case NavigationUnit.PAGE_UP:
				case NavigationUnit.PAGE_DOWN:
				{
					// TODO : Will need to handle scrolling here
					break;
				}


				default:
					return super.getNavigationDestinationIndex( currentIndex, navigationUnit, arrowKeysWrapFocus );
			}

			return Math.max( 0, Math.min( maxIndex, newIndex ) );
		}

		//--------------------------------------------------------------------------
		//  Drop methods
		//--------------------------------------------------------------------------

		private function calculateDropOverIndex( x:Number, y:Number ):int
		{
			var count:uint = this.target.numElements;
			if( count == 0 )
			{
				return 0;
			}

			var leftIndex:int = -1;

			for( var ii:int = 0; ii < count; ii++ )
			{
				var elementBounds:Rectangle = this.getElementBounds( ii );
				if( !elementBounds )
				{
					continue;
				}

				if( y >= elementBounds.y &&
					y <= ( elementBounds.y + elementBounds.height + this._verticalGap ) )
				{
					if( x >= elementBounds.x &&
						x <= ( elementBounds.x + elementBounds.width + this._horizontalGap ) )
					{
						return ii;
					}
					else
					{
						leftIndex = ii;
					}
				}
			}

			return leftIndex >= 0 ? leftIndex : count - 1;
		}

		override protected function calculateDropIndex( x:Number, y:Number ):int
		{
			var index:int = this.calculateDropOverIndex( x, y );

			var elementBounds:Rectangle = this.getElementBounds( index );
			if( elementBounds )
			{
				if( x >= ( elementBounds.x + elementBounds.width / 2 ) || y > ( elementBounds.y + elementBounds.height ) )
				{
					index++;
				}
			}

			return index;
		}

		override protected function calculateDropIndicatorBounds( dropLocation:DropLocation ):Rectangle
		{
			var overIndex:int = this.calculateDropOverIndex( dropLocation.dropPoint.x, dropLocation.dropPoint.y );
			var dropIndex:int = dropLocation.dropIndex;
			var count:int = this.target.numElements;
			var gap:Number = this._horizontalGap;

			// Special case, if we insert at the end, and the gap is negative, consider it to be zero
			if( gap < 0 && dropIndex == count )
			{
				gap = 0;
			}

			var dropElementBounds:Rectangle = this.getElementBounds( dropIndex );
			var overElementBounds:Rectangle = this.getElementBounds( overIndex );

			var emptySpace:Number = ( gap > 0 ) ? gap : 0;
			var emptySpaceLeft:Number = 0;
			if( count > 0 )
			{
				emptySpaceLeft = ( dropIndex < count && dropIndex == overIndex ) ? dropElementBounds.left - emptySpace : overElementBounds.right + gap - emptySpace;
			}

			// Calculate the size of the bounds, take minimum and maximum into account
			var width:Number = emptySpace;
			var height:Number = ( dropIndex == overIndex ) ? dropElementBounds.height : overElementBounds.height;
			if( this.dropIndicator is IVisualElement )
			{
				var element:IVisualElement = IVisualElement( this.dropIndicator );
				width = Math.max( Math.min( width, element.getMaxBoundsWidth( false ) ), element.getMinBoundsWidth( false ) );
			}

			var x:Number = emptySpaceLeft + Math.round( ( emptySpace - width ) / 2 );
			// Allow 1 pixel overlap with container border
			x = Math.max( -Math.ceil( width / 2 ), Math.min( this.target.contentWidth - Math.ceil( width / 2 ), x ) );
			var y:Number = ( dropIndex == overIndex ) ? dropElementBounds.top : overElementBounds.top;

			return new Rectangle( x, y, width, height );
		}
	}
}
