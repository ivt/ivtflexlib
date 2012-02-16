package com.ivt.flex.validators
{
	import mx.validators.ValidationResult;
	import mx.validators.Validator;

	// Validate that two fields are the same.
	public class SameAsValidator extends Validator
	{
		[Bindable]
		public var invalidError:String = "These fields are not the same.";
		[Bindable]
		public var sameAsSource:Object;
		[Bindable]
		public var sameAsProperty:String;

		public static function validateSameAs( validator:SameAsValidator, value:Object, baseField:String = null ):Array
		{
			var results:Array = [];
			var string:String = String( value );

			if( string != validator.sameAsSource[ validator.sameAsProperty ] )
			{
				results.push( new ValidationResult( true, baseField, "invalid", validator.invalidError ) );
			}

			return results;
		}

		public function SameAsValidator()
		{
			super();
		}

		override protected function doValidation( value:Object ):Array
		{
			var results:Array = super.doValidation( value );
            // Return if there are errors or if the required property is set to false and length is 0.
			var val:String = value ? String( value ) : "";
			if( results.length > 0 || ((val.length == 0) && !super.required) )
			{
				return results;
			}
			else
			{
				return SameAsValidator.validateSameAs( this, value,  null );
			}
		}
	}
}
