package com.ivt.flex.validators
{
	import com.ivt.flex.utils.HelperDate;

	import mx.validators.ValidationResult;
	import mx.validators.Validator;

	// Validates that a date is within range
	public class DateValidator extends Validator
	{
		[Bindable]
		public var tooEarlyError:String = "The date must be later than";
		[Bindable]
		public var tooLateError:String = "The date must be earlier than";

		[Bindable]
		public var minDate:Date;
		[Bindable]
		public var maxDate:Date;

		public static function validateDate( validator:DateValidator, value:Object, baseField:String = null ):Array
		{
			var results:Array = [];
			var date:Date = value as Date;

			if( date < validator.minDate )
			{
				results.push( new ValidationResult( true, baseField, "invalid", validator.tooEarlyError + " " + HelperDate.formatDate( validator.minDate, "DD/MM/YYYY" ) ) );
			}

			if( date > validator.maxDate )
			{
				results.push( new ValidationResult( true, baseField, "invalid", validator.tooLateError + " " + HelperDate.formatDate( validator.maxDate, "DD/MM/YYYY" ) ) );
			}

			return results;
		}

		public function DateValidator()
		{
			super();
		}

		override protected function doValidation( value:Object ):Array
		{
			var results:Array = super.doValidation( value );
			// Return if there are errors or if the required property is set to false and length is 0.
			var val:Date = value ? value as Date : null;
			if( results.length > 0 || ((val == null) && !super.required) )
			{
				return results;
			}
			else
			{
				return DateValidator.validateDate( this, value,  null );
			}
		}
	}
}
