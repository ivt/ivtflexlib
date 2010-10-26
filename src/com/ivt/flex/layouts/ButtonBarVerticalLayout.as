package com.ivt.flex.layouts
{
	import mx.core.ILayoutElement;

	import spark.components.supportClasses.GroupBase;
	import spark.layouts.supportClasses.LayoutBase;

	/**
	 *  The ButtonBarVerticalLayout class is a layout specifically designed for the
	 *  Spark ButtonBar skins.
	 *  The layout lays out the children vertically, top to bottom.
	 *
	 *  <p>The layout attempts to size all children to their preferred size.
	 *  If there is enough space, each child is set to its preferred size, plus any
	 *  excess space evenly distributed among the children.</p>
	 *
	 *  <p>If there is not enough space for all the children to be sized to their
	 *  preferred size, then the children that are smaller than the average height
	 *  are allocated their preferred size and the rest of the elements are
	 *  reduced equally.</p>
	 *
	 *  <p>All children are set to the width of the parent.</p>
	 */
	public class ButtonBarVerticalLayout extends LayoutBase
	{
		public function ButtonBarVerticalLayout():void
		{
			super();
		}

		//--------------------------------------------------------------------------
		//  Properties
		//--------------------------------------------------------------------------

		//----------------------------------
		//  gap
		//----------------------------------

		private var _gap:int = 0;

		[Inspectable(category="General")]

		/**
		 *  The vertical space between layout elements.
		 *
		 *  Note that the gap is only applied between layout elements, so if there's
		 *  just one element, the gap has no effect on the layout.
		 */
		public function get gap():int
		{
			return _gap;
		}

		public function set gap(value:int):void
		{
			if( this._gap == value )
			{
				return;
			}

			this._gap = value;

			var g:GroupBase = this.target;
			if( g )
			{
				g.invalidateSize();
				g.invalidateDisplayList();
			}
		}

		//--------------------------------------------------------------------------
		//  Methods
		//--------------------------------------------------------------------------

		override public function measure():void
		{
			super.measure();

			var layoutTarget:GroupBase = this.target;
			if( !layoutTarget )
			{
				return;
			}

			var elementCount:int = 0;
			var gap:Number = this.gap;

			var width:Number = 0;
			var height:Number = 0;

			var count:int = layoutTarget.numElements;
			for( var i:int = 0; i < count; i++ )
			{
				var layoutElement:ILayoutElement = layoutTarget.getElementAt( i );
				if( !layoutElement || !layoutElement.includeInLayout )
				{
					continue;
				}

				height += layoutElement.getPreferredBoundsHeight();
				elementCount++;
				width = Math.max( width, layoutElement.getPreferredBoundsWidth() );
			}

			if( elementCount > 1 )
			{
				height += gap * (elementCount - 1);
			}

			layoutTarget.measuredWidth = width;
			layoutTarget.measuredHeight = height;
		}

		override public function updateDisplayList( width:Number, height:Number ):void
		{
			var gap:Number = this.gap;
			super.updateDisplayList( width, height );

			var layoutTarget:GroupBase = this.target;
			if( !layoutTarget )
			{
				return;
			}

			// Pass one: calculate the excess space
			var totalPreferredHeight:Number = 0;
			var count:int = layoutTarget.numElements;
			var elementCount:int = count;
			var layoutElement:ILayoutElement;
			for( var i:int = 0; i < count; i++ )
			{
				layoutElement = layoutTarget.getElementAt( i );
				if( !layoutElement || !layoutElement.includeInLayout )
				{
					elementCount--;
					continue;
				}
				totalPreferredHeight += layoutElement.getPreferredBoundsHeight();
			}

			// Special case for no elements
			if( elementCount == 0 )
			{
				layoutTarget.setContentSize( 0, 0 );
				return;
			}

			// The content size is always the parent size
			layoutTarget.setContentSize( width, height );

			// Special case: if height is zero, make the gap zero as well
			if( height == 0 )
			{
				gap = 0;
			}

			// excessSpace can be negative
			var excessSpace:Number = height - totalPreferredHeight - gap * (elementCount - 1);
			var heightToDistribute:Number = height - gap * (elementCount - 1);

			// Special case: when we don't have enough space we need to count
			// the number of children smaller than the average size.
			var averageHeight:Number;
			var largeChildrenCount:int = elementCount;
			if( excessSpace < 0 )
			{
				averageHeight = height / elementCount;
				for( i = 0; i < count; i++ )
				{
					layoutElement = layoutTarget.getElementAt( i );
					if( !layoutElement || !layoutElement.includeInLayout )
					{
						continue;
					}

					var preferredHeight:Number = layoutElement.getPreferredBoundsHeight();
					if( preferredHeight <= averageHeight )
					{
						heightToDistribute -= preferredHeight;
						largeChildrenCount--;
					}
				}
				heightToDistribute = Math.max( 0, heightToDistribute );
			}

			// Resize and position children
			var y:Number = 0;
			var childHeight:Number = NaN;
			var childHeightRounded:Number = NaN;
			var roundOff:Number = 0;
			for( i = 0; i < count; i++ )
			{
				layoutElement = layoutTarget.getElementAt( i );
				if( !layoutElement || !layoutElement.includeInLayout )
				{
					continue;
				}

				if( excessSpace > 0 )
				{
					childHeight = heightToDistribute * layoutElement.getPreferredBoundsHeight() / totalPreferredHeight;
				}
				else if( excessSpace < 0 )
				{
					childHeight = (averageHeight < layoutElement.getPreferredBoundsHeight()) ? heightToDistribute / largeChildrenCount : NaN;  
				}

				if( !isNaN( childHeight ) )
				{
					// Round, we want integer values
					childHeightRounded = Math.round( childHeight + roundOff );
					roundOff += childHeight - childHeightRounded;
				}

				layoutElement.setLayoutBoundsSize( width, childHeightRounded );
				layoutElement.setLayoutBoundsPosition( 0, y );

				// No need to round, height should be an integer number
				y += gap + layoutElement.getLayoutBoundsHeight();

				// Reset childHeightRounded
				childHeightRounded = NaN;
			}
		}
	}
}
