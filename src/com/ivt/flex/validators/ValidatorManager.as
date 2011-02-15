package com.ivt.flex.validators
{
	import com.ivt.flex.controls.TextInput;

	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import mx.containers.FormItem;
	import mx.core.Container;
	import mx.core.IMXMLObject;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.events.ValidationResultEvent;
	import mx.validators.NumberValidator;
	import mx.validators.StringValidator;
	import mx.validators.Validator;

	import spark.components.RadioButton;
	import spark.components.RadioButtonGroup;
	import spark.components.supportClasses.GroupBase;
	import spark.components.supportClasses.ListBase;
	import spark.components.supportClasses.SkinnableContainerBase;
	import spark.components.supportClasses.SkinnableTextBase;

	[Event(name="valid", type="mx.events.ValidationResultEvent")]
	[Event(name="invalid", type="mx.events.ValidationResultEvent")]

	/**
	 *  The ValidatorManager component manages validators and automagically creates
	 *  default validators for certain field types.
	 *
	 *  See: http://www.adobe.com/devnet/flex/quickstarts/validating_data.html
	 *
	 *  <p>Notice that the ValidatorManager component is a subclass of EventDispatcher,
	 *  not UIComponent, and implements the IMXMLObject interface.
	 *  The ValidatorManager component declaration must
	 *  be contained within the <code>&lt;Declarations&gt;</code> tag since it is
	 *  not assignable to IVisualElement.</p>
	 *
	 *  @mxml
	 *
	 *  <p>The <code>&lt;s:ValidatorManager&gt;</code> tag inherits all of the
	 *  tag attributes of its superclass, and adds the following tag attributes:</p>
	 *
	 *  <pre>
	 *  &lt;s:ValidatorManager
	 *    <strong>Properties</strong>
	 *    validators=""
	 *    requiredFields=""
	 *    isValid="false"
	 *
	 *    <strong>Events</strong>
	 *    valid="<i>No default</i>"
	 *    invalid="<i>No default</i>"
	 *  /&gt;
	 *  </pre>
	 */
	public class ValidatorManager extends EventDispatcher implements IMXMLObject
	{
		[Bindable]
		public var validators:Vector.<Validator> = new Vector.<Validator>();

		[Bindable]
		public var requiredFields:Array = [];

		[Bindable]
		public var isValid:Boolean = false;

		public var formItemsRequired:Boolean = true;

		public function ValidatorManager()
		{
			super();
		}

		public function reset():void
		{
			this.isValid = true;
			for each( var validator:Validator in this.validators )
			{
				validator.source.errorString = "";
			}
		}

		public function validate( object:Object = null ):Boolean
		{
			if( object )
			{
				return this.isObjectValid( object );
			}
			else
			{
				return this.doValidate();
			}
		}

		public function validateChildren( object:Object ):Boolean
		{
			var ii:int;
			var child:Object;
			var valid:Boolean = true;

			if( object is GroupBase )
			{
				var groupBase:GroupBase = object as GroupBase;
				for( ii = 0; ii < groupBase.numElements; ii++ )
				{
					child = groupBase.getElementAt( ii );
					valid = this.isObjectValid( child ) && this.validateChildren( child );
					if( !valid )
					{
						return false;
					}
				}
			}
			else if( object is Container )
			{
				var container:Container = object as Container;
				for( ii = 0; ii < container.numElements; ii++ )
				{
					child = container.getElementAt( ii );
					valid = this.isObjectValid( child ) && this.validateChildren( child );
					if( !valid )
					{
						return false;
					}
				}
			}
			else if( object is SkinnableContainerBase )
			{
				var skinnableContainer:SkinnableContainerBase = object as SkinnableContainerBase;
				for( ii = 0; ii < skinnableContainer.numChildren; ii++ )
				{
					child = skinnableContainer.getChildAt( ii );
					valid = this.isObjectValid( child ) && this.validateChildren( child );
					if( !valid )
					{
						return false;
					}
				}
			}
			else if( object is RadioButton )
			{
				var radioButton:RadioButton = object as RadioButton;
				if( !this.isObjectValid( radioButton.group ) )
				{
					return false;
				}
			}

			return true;
		}

		public function getValidatorForField( field:Object ):Validator
		{
			for each( var validator:Validator in this.validators )
			{
				if( validator.source == field )
				{
					return validator;
				}
			}
			return null;
		}

		// ----- IMXMLObject -----
		public function initialized( document:Object, id:String ):void
		{
			document.addEventListener( FlexEvent.CREATION_COMPLETE, this.onParentCreationComplete );
		}

		protected function onParentCreationComplete( event:FlexEvent ):void
		{
			event.target.removeEventListener( FlexEvent.CREATION_COMPLETE, this.onParentCreationComplete );

			// Create validators for the required fields
			for each( var field:String in this.requiredFields )
			{
				if( event.target[ field ] )
				{
					if( event.target[ field ] is SkinnableTextBase )
					{
						var textBaseValidator:StringValidator = new StringValidator();
						textBaseValidator.source = event.target[ field ];
						textBaseValidator.property = "text";
						textBaseValidator.minLength = 1;
						textBaseValidator.required = true;
						this.validators.push( textBaseValidator );
					}
					else if( event.target[ field ] is ListBase )
					{
						var listBaseValidator:NumberValidator = new NumberValidator();
						listBaseValidator.source = event.target[ field ];
						listBaseValidator.property = "selectedIndex";
						listBaseValidator.minValue = 0;
						listBaseValidator.lowerThanMinError = "A selection has not been made.";
						listBaseValidator.required = true;
						this.validators.push( listBaseValidator );
					}
					else if( event.target[ field ] is RadioButtonGroup )
					{
						var radioGroupValidator:Validator = new Validator();
						radioGroupValidator.source = event.target[ field ];
						radioGroupValidator.property = "selection";
						radioGroupValidator.required = true;
						this.validators.push( radioGroupValidator );
					}
					else
					{
						trace( event.target.label +  ": Unhandled type for: " + field );
					}
				}
				else
				{
					trace( event.target.label +  ": Field not found: " + field );
				}
			}

			// Initialize all the validators
			for each( var validator:Validator in this.validators )
			{
				if( validator.source )
				{
					if( validator.source is TextInput )
					{
						validator.source.addEventListener( TextInput.DELAYED_CHANGED, this.onControlChanged );
						validator.source.delay = 400;
					}
					else if( validator.source is RadioButtonGroup )
					{
						validator.source.addEventListener( ItemClickEvent.ITEM_CLICK, this.onRadioGroupChanged );
					}
					else
					{
						validator.source.addEventListener( Event.CHANGE, this.onControlChanged );
					}

					if( this.formItemsRequired )
					{
						var component:UIComponent = validator.source as UIComponent;

						// If the source isn't a UIComponent, check if it's a RadioButtonGroup and use one of its radio buttons instead.
						if( !component )
						{
							var rbg:RadioButtonGroup = validator.source as RadioButtonGroup;
							if( rbg && rbg.numRadioButtons > 0 )
							{
								component = rbg.getRadioButtonAt( 0 );
							}
						}

						// If this component is inside a form item, change the FormItems required flag to match the validator
						if( component )
						{
							var parent:FormItem = component.parent as FormItem;
							if( parent && parent.enabled )
							{
								parent.required = validator.required;
							}
						}
					}
				}
			}
		}

		protected function onControlChanged( event:Event ):void
		{
			this.doValidate( (event.target as DisplayObject) );
		}

		protected function onRadioGroupChanged( event:ItemClickEvent ):void
		{
			this.doValidate();
		}

		protected function doValidate( focusedControl:DisplayObject = null ):Boolean
		{
			var valid:Boolean = true;

			for each( var validator:Validator in this.validators )
			{
				valid = this.isValidatorValid( validator, focusedControl ) && valid;
			}

			this.isValid = valid;
			this.dispatchEvent( new ValidationResultEvent( valid ? ValidationResultEvent.VALID : ValidationResultEvent.INVALID ) );
			return valid;
		}

		private function isComponentEnabled( component:UIComponent ):Boolean
		{
			while( component )
			{
				if( !component.enabled )
				{
					return false;
				}

				component = component.parent as UIComponent;
			}

			return true;
		}

		private function isValidatorValid( validator:Validator, focusedObject:Object = null ):Boolean
		{
			var validate:Boolean = true;
			var valid:Boolean = true;

			var component:UIComponent = validator.source as UIComponent;
			if( !this.isComponentEnabled( component ) || !validator.enabled )
			{
				validate = false;
				component.errorString = "";
			}

			if( validate )
			{
				var suppressEvents:Boolean = (validator.source != focusedObject);
				var resultEvent:ValidationResultEvent = validator.validate( null, suppressEvents );
				valid = (resultEvent.type == ValidationResultEvent.VALID);
			}

			return valid;
		}

		private function isObjectValid( object:Object ):Boolean
		{
			for each( var validator:Validator in this.validators )
			{
				if( validator.source == object )
				{
					return this.isValidatorValid( validator );
				}
			}

			return true;
		}
	}
}
