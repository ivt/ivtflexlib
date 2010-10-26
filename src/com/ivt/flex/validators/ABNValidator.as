package com.ivt.flex.validators
{
	import mx.validators.ValidationResult;
	import mx.validators.Validator;

	// Validates Australian Business Numbers (ABN)
	// See:  http://www.ato.gov.au/businesses/content.asp?doc=/content/13187.htm
	//
	// 1. Subtract 1 from the first (left) digit to give a new eleven digit number
	// 2. Multiply each of the digits in this new number by its weighting factor
	// 3. Sum the resulting 11 products
	// 4. Divide the total by 89, noting the remainder
	// 5. If the remainder is zero the number is valid

	public class ABNValidator extends Validator
	{
		[Bindable]
		public var invalidError:String = "This number is not a valid ABN.";

		private static const weights:Array = [ 10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19 ];

		public static function validateABN( validator:ABNValidator, value:Object, baseField:String = null ):Array
		{
			var results:Array = [];
			var sum:int = 0;
			var digits:Array = [];
			var string:String = String( value );

			for( var ii:int = 0; ii < string.length; ii++ )
			{
				var chr:String = string.charAt( ii );
				if( chr >= "0" && chr <= "9" )
				{
					digits.push( parseInt( chr ) );
				}
			}

			if( digits.length == 11 )
			{
				digits[ 0 ] = digits[ 0 ] - 1;
				for( ii = 0; ii < digits.length; ii++ )
				{
					digits[ ii ] = digits[ ii ] * ABNValidator.weights[ ii ];
					sum += digits[ ii ];
				}
			}

			if( sum % 89 != 0 || digits.length != 11 )
			{
				results.push( new ValidationResult( true, baseField, "invalid", validator.invalidError ) );
			}

			return results;
		}

		public function ABNValidator()
		{
			super();
		}

		override protected function doValidation( value:Object ):Array
		{
			var results:Array = super.doValidation( value );

            // Return if there are errors
            // or if the required property is set to false and length is 0.
			var val:String = value ? String( value ) : "";
			if( results.length > 0 || ((val.length == 0) && !super.required) )
			{
				return results;
			}
			else
			{
				return ABNValidator.validateABN( this, value, null );
			}
		}
	}
}
