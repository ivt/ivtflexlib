package com.ivt.flex.controls
{
	import com.ivt.flex.controls.listClasses.NonSelectableIndentedItemRenderer;
	import com.ivt.flex.controls.listClasses.NonSelectableItemRenderer;
	import com.ivt.flex.controls.listClasses.OptgroupItemRenderer;
	import com.ivt.flex.controls.listClasses.SelectableIndentedItemRenderer;

	import flash.events.*;
	import flash.utils.getTimer;

	import mx.core.ClassFactory;
	import mx.core.mx_internal;
	import mx.events.*;

	import spark.components.DropDownList;
	import spark.core.NavigationUnit;
	import spark.skins.spark.DefaultItemRenderer;

	use namespace mx_internal;

	/**
	 * Thanks to http://flexponential.com/2010/01/31/spark-dropdownlist-equivalent-of-the-html-optgroup-concept/
	 * for the disabled items/optgroup header code.
	 */
	public class DropDownList extends spark.components.DropDownList
	{
		public var sizeToFit:Boolean = false;
		public var isHeaderFunction:Function;
		public var isEnabledFunction:Function;
		public var typeAheadTimeout:int = 1000; // 1 second

		public function DropDownList()
		{
			super();

			this.addEventListener( "dataProviderChanged", this.onDataProviderChange );
			this.addEventListener( CollectionEvent.COLLECTION_CHANGE, this.onDataProviderChange );
		}

		private var _propertyField:String = "serial";
		private var _selectedProperty:Object = null;
		private var _selectedPropertyChanged:Boolean = false;
		private var _dataProviderChanged:Boolean = false;
		private var _findString:String = "";
		private var _lastKeyDownTime:int = 0;

		/**
		 * Lazily finds out the selected property based on the currently selected item.
		 * May not be the same as when you specified set selectedProperty.
		 * @return
		 */
		public function get selectedProperty():Object
		{
			if ( this._propertyField != null && this.selectedItem != null && this.selectedItem.hasOwnProperty( this._propertyField ) )
			{
				return this.selectedItem[ this._propertyField ];
			}
			else
			{
				return null;
			}
		}

		public function set selectedProperty( value:Object ):void
		{
			this._selectedProperty = value;
			this._selectedPropertyChanged = true;

			if ( this.dataProvider == null )
			{
				// Give the dataProvider a change to be set before the next frame, so that if we set selectedProperty
				// BEFORE dataProvider, we still work...
				this.invalidateProperties();
			}
			else
			{
				// Otherwise we can just force this now...
				this.commitSelectedProperty();
			}
		}

		public function get propertyField():String { return this._propertyField; }
		public function set propertyField( value:String ):void
		{
			this._propertyField = value;
			this.invalidateProperties();
		}

		[Deprecated(replacement="selectedProperty")]

		/**
		 * An alias to selected property, but casts as an int and returns it.
		 * This will return 0 if selected property is not an int or Number or is null.
		 * @return
		 */
		public function get selectedSerial():int
		{
			var item:Object = this.selectedProperty;
			if ( item != null && ( item is int || item is Number ) )
			{
				return item as int;
			}
			else
			{
				return 0;
			}
		}

		public function set selectedSerial( value:int ):void
		{
			this.selectedProperty = value;
		}

		[Deprecated(replacement="propertyField and selectedProperty")]

		/**
		 * An alias to propertyField.
		 */
		public function set serialField( value:String ):void
		{
			this.propertyField = value;
		}

		/**
		 * Refactored outside of commitProperties, so that we can attempt to call it ourselves.
		 * This is because of some obscure and confusing behaviour which I *think* is related to invalidateProperties
		 * being called from within commitProperties. Maybe something to do with the singleton flex object responsible
		 * for invalidation...
		 */
		private function commitSelectedProperty():void
		{
			if ( ( this._selectedPropertyChanged || this._dataProviderChanged ) && this.dataProvider != null && this._propertyField != null )
			{
				var found:Boolean = false;
				this._selectedPropertyChanged = false;
				this._dataProviderChanged = false;
				for ( var i:int = 0; i < this.dataProvider.length; i ++ )
				{
					var item:Object = this.dataProvider.getItemAt( i );
					if ( item != null && item.hasOwnProperty( this._propertyField ) && item[ this._propertyField ] == this._selectedProperty )
					{
						found = true;
						this.selectedItem = item;

						// Seems to work, but it didn't display the label for the selected item in some cases, so I will
						// help it along... Hope this doesn't bust any display stuff.
						this.updateLabelDisplay( item );
						break;
					}
				}

				if( !found )
				{
					this.selectedItem = null;
					this.updateLabelDisplay( null );
				}
			}
		}

		protected override function commitProperties():void
		{
			this.commitSelectedProperty();

			// Perform this AFTER we check the selectedProperty, because our code will potentially require validation of selectedIndex.
			super.commitProperties();
		}
		
		private function onDataProviderChange( event:Event = null ):void
		{
			this._dataProviderChanged = true;
			this.findTypicalItem();
		}

		private function findTypicalItem():void
		{
			if ( this.dataProvider )
			{
				// Setting 'typicalItem' to the longest item will cause the control to be sized accordingly
				if( this.sizeToFit )
				{
					var longestLength:int = 0;
					var longestItem:Object = null;

					for ( var i:int = 0; i < this.dataProvider.length; i ++ )
					{
						var item:Object = this.dataProvider.getItemAt( i );
						if( null != item && item.hasOwnProperty( this.labelField ) )
						{
							var label:String = item[ this.labelField ] as String;
							if( label && label.length >= longestLength )
							{
								longestLength = label.length;
								longestItem = item;
							}
						}
					}

					this.typicalItem = longestItem;
				}
			}
			else
			{
				this.typicalItem = null;
			}
		}


        /**
         * Override the setSelectedIndex() mx_internal method to not select an item that
         * is forbidden to be selected...
         */
        override mx_internal function setSelectedIndex( value:int, dispatchChangeEvent:Boolean = false ):void
        {
            if( value == this.selectedIndex )
            {
                return;
            }

            if( value >= 0 && this.dataProvider != null && value < this.dataProvider.length )
            {
                if( this.isSelectable( this.dataProvider.getItemAt( value ) ) != false )
                {

                    if( dispatchChangeEvent )
                    {
                        this.dispatchChangeAfterSelection = dispatchChangeEvent;
                    }

                    this._proposedSelectedIndex = value;
                    this.invalidateProperties();
                }
            }
            else
            {
                if( dispatchChangeEvent )
                {
                    this.dispatchChangeAfterSelection = dispatchChangeEvent;
                }

                this._proposedSelectedIndex = value;
                this.invalidateProperties();
            }
        }

        /**
         * Override the setSelectedIndex() mx_internal method to not select an item that
         * is forbidden to be selected...
         */
        override mx_internal function setSelectedIndices(value:Vector.<int>, dispatchChangeEvent:Boolean = false):void
        {
            var newValue:Vector.<int> = new Vector.<int>;
            // take out indices that are on items that are not able to be selected...

            for( var i:int = 0; i < value.length; i++ )
            {

                var item:* = dataProvider.getItemAt(value[i]);

                if( !this.isSelectable( item ) )
                {
                    continue;
                }

                newValue.push(value[i]);
            }

            super.setSelectedIndices(newValue, dispatchChangeEvent);
        }

		override mx_internal function findKey( eventCode:int ):Boolean
		{
			if( !this.dataProvider || this.dataProvider.length == 0 )
			{
				return false;
			}

			if( eventCode >= 33 && eventCode <= 126 )
			{
				var matchingIndex:Number;
				this._findString += String.fromCharCode( eventCode );
				var startIndex:int = this.isDropDownOpen ? this.userProposedSelectedIndex  + 1 : this.selectedIndex + 1;
				startIndex = Math.max( 0, startIndex );

				matchingIndex = findStringLoop( this._findString, startIndex, this.dataProvider.length );

				// We didn't find the item, loop back to the top
				if( matchingIndex == -1 )
				{
					matchingIndex = this.findStringLoop( this._findString, 0,  startIndex );
				}

				if( matchingIndex != -1 )
				{
					if( this.isDropDownOpen )
						this.changeHighlightedSelection( matchingIndex );
					else
						this.setSelectedIndex( matchingIndex, true );

					return true;
				}
			}

			return false;
		}

        /**
         *  Override the keyDownHandler() to skip unselectable items
         */
        override protected function keyDownHandler( event:KeyboardEvent ) : void
        {
            if( !this.enabled )
            {
                return;
            }

	        // Reset type ahead find string if necessary
	        var time:int = getTimer();
	        if( time - this._lastKeyDownTime > this.typeAheadTimeout )
	        {
		        this._findString = "";
	        }
	        this._lastKeyDownTime = time;

            if( !this.dropDownController.processKeyDown( event ) )
            {
                var navigationUnit:uint = event.keyCode;

                if( this.findKey( event.charCode ) )
                {
                    event.preventDefault();
                    return;
                }

                if( !NavigationUnit.isNavigationUnit( navigationUnit ) )
                {
                    return;
                }

                var proposedNewIndex:int = NO_SELECTION;
                var currentIndex:int;

                if( this.isDropDownOpen )
                {
                    // Normalize the proposed index for getNavigationDestinationIndex
                    currentIndex = this.userProposedSelectedIndex < NO_SELECTION ? NO_SELECTION : this.userProposedSelectedIndex;
                    proposedNewIndex = this.layout.getNavigationDestinationIndex( currentIndex, navigationUnit, arrowKeysWrapFocus );

                    //
                    // Flexponential: Added logic here to skip over indices that are not selectable
                    //
                    while( !this.isSelectable( this.dataProvider.getItemAt( proposedNewIndex ) ) )
                    {
                        if (navigationUnit == NavigationUnit.DOWN ||
                            navigationUnit == NavigationUnit.PAGE_DOWN ||
                            navigationUnit == NavigationUnit.HOME)
                        {
                            proposedNewIndex++;
						}

                        else if (navigationUnit == NavigationUnit.UP ||
                            navigationUnit == NavigationUnit.PAGE_UP ||
                            navigationUnit == NavigationUnit.END)
                        {
                            proposedNewIndex--;
						}

                        if ( proposedNewIndex >= this.dataProvider.length || proposedNewIndex < 0 )
                        {
                            return;
                        }
                    }

                    if( proposedNewIndex != NO_SELECTION )
                    {
                        this.changeHighlightedSelection( proposedNewIndex );
                        event.preventDefault();
                    }
                }
                else if( this.dataProvider )
                {
                    var maxIndex:int = this.dataProvider.length - 1;

                    // Normalize the proposed index for getNavigationDestinationIndex
                    currentIndex = this.caretIndex < NO_SELECTION ? NO_SELECTION : this.caretIndex;

                    switch( navigationUnit )
                    {
                        case NavigationUnit.UP:
                        {
                            if (arrowKeysWrapFocus &&
                                (currentIndex == 0 ||
                                    currentIndex == NO_SELECTION ||
                                    currentIndex == CUSTOM_SELECTED_ITEM))
                            {
                                proposedNewIndex = maxIndex;
                            }
                            else
                            {
                                proposedNewIndex = currentIndex - 1;
                            }
                            event.preventDefault();
                            break;
                        }

                        case NavigationUnit.DOWN:
                        {
                            if (arrowKeysWrapFocus &&
                                (currentIndex == maxIndex ||
                                    currentIndex == NO_SELECTION ||
                                    currentIndex == CUSTOM_SELECTED_ITEM))
                            {
                                proposedNewIndex = 0;
                            }
                            else
                            {
                                proposedNewIndex = currentIndex + 1;
                            }
                            event.preventDefault();
                            break;
                        }

                        case NavigationUnit.PAGE_UP:
                        {
                            proposedNewIndex = currentIndex == NO_SELECTION ?
                                NO_SELECTION : Math.max(currentIndex - PAGE_SIZE, 0);
                            event.preventDefault();
                            break;
                        }

                        case NavigationUnit.PAGE_DOWN:
                        {
                            proposedNewIndex = currentIndex == NO_SELECTION ?
                                PAGE_SIZE : (currentIndex + PAGE_SIZE);
                            event.preventDefault();
                            break;
                        }

                        case NavigationUnit.HOME:
                        {
                            proposedNewIndex = 0;
                            event.preventDefault();
                            break;
                        }

                        case NavigationUnit.END:
                        {
                            proposedNewIndex = maxIndex;
                            event.preventDefault();
                            break;
                        }

                    }

                    proposedNewIndex = Math.min(proposedNewIndex, maxIndex);
                    if (proposedNewIndex >= 0)
                    {
						this.setSelectedIndex(proposedNewIndex, true);
                    }
                }
            }
            else
            {
                event.preventDefault();
            }

        }

		/**
		 * Checks whether or not a particular item is selectable, based on the isHeader/isEnabled functions...
		 * @param item
		 */
		private function isSelectable( item:Object ):Boolean
		{
			var selectable:Boolean = true;
			if ( this.isHeaderFunction != null )
			{
				selectable = selectable && !this.isHeaderFunction.call( -1, item );
			}
			if ( this.isEnabledFunction != null )
			{
				selectable = selectable && this.isEnabledFunction.call( -1, item );
			}
			return selectable;
		}

		/**
		 * Decides whether to create an option group renderer, a non selectable renderer, or an indented renderer.
		 * Set itemRendererFunction to this if you wish to have the DropDownList create option group renderers.
		 * @param item
		 * @return
		 */
		public function optionGroupItemRendererFunction( item:Object ):ClassFactory
		{
			if ( this.isEnabledFunction == null && this.isHeaderFunction == null )
			{
				return new ClassFactory( DefaultItemRenderer );
			}
			else if ( this.isEnabledFunction != null && this.isHeaderFunction == null )
			{
				// If header function is not specified, then none of the items will ever be headers, and thus we will
				// never need to indent any other items.
				return this.isEnabledFunction.call( -1, item ) ? new ClassFactory( DefaultItemRenderer ) : new ClassFactory( NonSelectableItemRenderer );
			}
			else if ( this.isHeaderFunction != null && this.isEnabledFunction == null)
			{
				// Header items may exist, so for the non-header items, we will indent them...
				return this.isHeaderFunction.call( -1, item ) ? new ClassFactory( OptgroupItemRenderer ) : new ClassFactory( SelectableIndentedItemRenderer );
			}
			else
			{
				if ( this.isHeaderFunction.call( -1, item ) )
				{
					return new ClassFactory( OptgroupItemRenderer );
				}
				else if ( this.isEnabledFunction.call( -1, item ) )
				{
					return new ClassFactory( SelectableIndentedItemRenderer );
				}
				else
				{
					return new ClassFactory( NonSelectableIndentedItemRenderer );
				}
			}
		}
	}
}
