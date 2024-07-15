<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Setting_model extends CI_Model
{

    public function __construct()
    {
        parent::__construct();
        $this->load->database();
        $this->load->library(['ion_auth', 'form_validation']);
        $this->load->helper(['url', 'language', 'function_helper', 'timezone_helper']);
    }

    public function update_system_setting($post)
    {
        $post = escape_array($post);

        $system_data = [
            'system_configurations' => $post['system_configurations'],
            'system_timezone_gmt' => $post['system_timezone_gmt'],
            'system_configurations_id' => $post['system_configurations_id'],
            'app_name' => $post['app_name'],
            'support_number' => $post['support_number'],
            'support_email' => $post['support_email'],
            'current_version' => $post['current_version'],
            'current_version_ios' => $post['current_version_ios'],
            'is_version_system_on' => (isset($post['is_version_system_on'])) ? '1' : '0',
            'otp_login' => (isset($post['otp_login'])) ? '1' : '0',
            'google_login' => (isset($post['google_login'])) ? '1' : '0',
            // 'facebook_login' => (isset($post['facebook_login'])) ? '1' : '0',
            'apple_login' => (isset($post['apple_login'])) ? '1' : '0',
            'currency' => $post['currency'],
            'system_timezone' => $post['system_timezone'],
            'is_refer_earn_on' => (isset($post['is_refer_earn_on'])) ? '1' : '0',
            'tax' => (isset($post['tax'])) ? $post['tax'] : '0',
            'is_email_setting_on' => (isset($post['is_email_setting_on'])) ? '1' : '0',
            'google_map_api_key' => $post['google_map_api_key'],
            'google_map_javascript_api_key' => $post['google_map_javascript_api_key'],
            'min_refer_earn_order_amount' => $post['min_refer_earn_order_amount'],
            'refer_earn_bonus' => $post['refer_earn_bonus'],
            'refer_earn_method' => $post['refer_earn_method'],
            'max_refer_earn_amount' => $post['max_refer_earn_amount'],
            'refer_earn_bonus_times' => $post['refer_earn_bonus_times'],
            'minimum_cart_amt' => $post['minimum_cart_amt'],
            'low_stock_limit' => (isset($post['low_stock_limit'])) ? $post['low_stock_limit'] : '5',
            'max_items_cart' => $post['max_items_cart'],
            'is_rider_otp_setting_on' => (isset($post['is_rider_otp_setting_on'])) ? '1' : '0',
            'is_app_maintenance_mode_on' => (isset($post['is_app_maintenance_mode_on'])) ? '1' : '0',
            'is_rider_app_maintenance_mode_on' => (isset($post['is_rider_app_maintenance_mode_on'])) ? '1' : '0',
            // 'is_partner_app_maintenance_mode_on' => (isset($post['is_partner_app_maintenance_mode_on'])) ? '1' : '0',
            // 'is_web_maintenance_mode_on' => (isset($post['is_web_maintenance_mode_on'])) ? '1' : '0',
            'supported_locals' => (isset($post['supported_locals'])) ?  $post['supported_locals'] : '',
        ];

        $main_image_name = $post['logo'];
        $rider_main_image_name = $post['rider_logo'];

        $favicon_image_name = $post['favicon'];
        $rider_favicon_image_name = $post['rider_favicon'];
        $cover_image_name = $post['cover_image'];
        $rider_cover_image_name = $post['rider_cover_image'];
        // $light_image_name = $post['light_logo'];

        $system_data = json_encode($system_data);
        $query = $this->db->get_where('settings', array(
            'variable' => 'system_settings'
        ));
        $count = $query->num_rows();
        if ($main_image_name != NULL && !empty($main_image_name)) {
            $logo_res = $this->db->get_where('settings', array(
                'variable' => 'logo'
            ));
            $logo_count = $logo_res->num_rows();
            if ($logo_count == 0) {
                $this->db->insert('settings', ['value' => $main_image_name, 'variable' => 'logo']);
            } else {
                $this->db->set('value', $main_image_name)->where('variable', 'logo')->update('settings');
            }
        }
        // rider logo
        if ($rider_main_image_name != NULL && !empty($rider_main_image_name)) {
            $rider_logo_res = $this->db->get_where('settings', array(
                'variable' => 'rider_logo'
            ));
            $rider_logo_count = $rider_logo_res->num_rows();
            if ($rider_logo_count == 0) {
                $this->db->insert('settings', ['value' => $rider_main_image_name, 'variable' => 'rider_logo']);
            } else {
                $this->db->set('value', $rider_main_image_name)->where('variable', 'rider_logo')->update('settings');
            }
        }
        // end

        // if ($light_image_name != NULL && !empty($light_image_name)) {
        //     $logo_res = $this->db->get_where('settings', array(
        //         'variable' => 'light_logo'
        //     ));
        //     $logo_count = $logo_res->num_rows();
        //     if ($logo_count == 0) {
        //         $this->db->insert('settings', ['value' => $light_image_name, 'variable' => 'light_logo']);
        //     } else {
        //         $this->db->set('value', $light_image_name)->where('variable', 'light_logo')->update('settings');
        //     }
        // }
        if ($favicon_image_name != NULL && !empty($favicon_image_name)) {
            $favicon_res = $this->db->get_where('settings', array(
                'variable' => 'favicon'
            ));
            $favicon_count = $favicon_res->num_rows();
            if ($favicon_count == 0) {
                $this->db->insert('settings', ['value' => $favicon_image_name, 'variable' => 'favicon']);
            } else {
                $this->db->set('value', $favicon_image_name)->where('variable', 'favicon')->update('settings');
            }
        }

        // rider fevicon
        if ($rider_favicon_image_name != NULL && !empty($rider_favicon_image_name)) {
            $rider_favicon_res = $this->db->get_where('settings', array(
                'variable' => 'rider_favicon'
            ));
            $rider_favicon_count = $rider_favicon_res->num_rows();
            if ($rider_favicon_count == 0) {
                $this->db->insert('settings', ['value' => $rider_favicon_image_name, 'variable' => 'rider_favicon']);
            } else {
                $this->db->set('value', $rider_favicon_image_name)->where('variable', 'rider_favicon')->update('settings');
            }
        }
        // end

        if ($cover_image_name != NULL && !empty($cover_image_name)) {
            // print_r("hello");
            $cover_image_res = $this->db->get_where('settings', array(
                'variable' => 'cover_image'
            ));
            $cover_image_count = $cover_image_res->num_rows();
            if ($cover_image_count == 0) {
                $this->db->insert('settings', ['value' => $cover_image_name, 'variable' => 'cover_image']);
            } else {
                $this->db->set('value', $cover_image_name)->where('variable', 'cover_image')->update('settings');
            }
        }

        // rider cover image
        if ($rider_cover_image_name != NULL && !empty($rider_cover_image_name)) {

            $rider_cover_image_res = $this->db->get_where('settings', array(
                'variable' => 'rider_cover_image'
            ));
            $rider_cover_image_count = $rider_cover_image_res->num_rows();
            if ($rider_cover_image_count == 0) {
                $this->db->insert('settings', ['value' => $rider_cover_image_name, 'variable' => 'rider_cover_image']);
            } else {
                $this->db->set('value', $rider_cover_image_name)->where('variable', 'rider_cover_image')->update('settings');
            }
        }

        // end

        if ($count === 0) {
            $data = array(
                'variable' => 'system_settings',
                'value' => $system_data
            );
            $this->db->insert('settings', $data);
            $this->db->insert('settings', ['value' => $post['currency']]);
        } else {
            $this->db->set('value', $system_data)->where('variable', 'system_settings')->update('settings');
            $this->db->set('value', $post['currency'])->where('variable', 'currency')->update('settings');
        }
    }


    public function update_payment_method($post)
    {

        $post = escape_array($post);

        $payment_data = array();
        $payment_data['paypal_payment_method'] = isset($post['paypal_payment_method']) ? '1' : '0';
        $payment_data['paypal_mode'] = isset($post['paypal_mode']) && !empty($post['paypal_mode']) ? $post['paypal_mode'] : '';
        $payment_data['paypal_business_email'] = isset($post['paypal_business_email']) && !empty($post['paypal_business_email']) ? $post['paypal_business_email'] : '';
        $payment_data['currency_code'] = isset($post['currency_code']) && !empty($post['currency_code']) ? $post['currency_code'] : '';

        $payment_data['razorpay_payment_method'] = isset($post['razorpay_payment_method']) ? '1' : '0';
        $payment_data['razorpay_key_id'] = isset($post['razorpay_key_id']) && !empty($post['razorpay_key_id']) ? $post['razorpay_key_id'] : '';
        $payment_data['razorpay_secret_key'] = isset($post['razorpay_secret_key']) && !empty($post['razorpay_secret_key']) ? $post['razorpay_secret_key'] : '';
        $payment_data['refund_webhook_secret_key'] = isset($post['refund_webhook_secret_key']) && !empty($post['refund_webhook_secret_key']) ? $post['refund_webhook_secret_key'] : '';


        $payment_data['paystack_payment_method'] = isset($post['paystack_payment_method']) ? '1' : '0';
        $payment_data['paystack_key_id'] = isset($post['paystack_key_id']) && !empty($post['paystack_key_id']) ? $post['paystack_key_id'] : '';
        $payment_data['paystack_secret_key'] = isset($post['paystack_secret_key']) && !empty($post['paystack_secret_key']) ? $post['paystack_secret_key'] : '';


        $payment_data['stripe_payment_method'] = isset($post['stripe_payment_method']) ? '1' : '0';
        $payment_data['stripe_payment_mode'] = isset($post['stripe_payment_mode']) ? $post['stripe_payment_mode'] : 'test';
        $payment_data['stripe_publishable_key'] = isset($post['stripe_publishable_key']) && !empty($post['stripe_publishable_key']) ? $post['stripe_publishable_key'] : '';
        $payment_data['stripe_secret_key'] = isset($post['stripe_secret_key']) && !empty($post['stripe_secret_key']) ? $post['stripe_secret_key'] : '';
        $payment_data['stripe_webhook_secret_key'] = isset($post['stripe_webhook_secret_key']) && !empty($post['stripe_webhook_secret_key']) ? $post['stripe_webhook_secret_key'] : '';
        $payment_data['stripe_currency_code'] = isset($post['stripe_currency_code']) && !empty($post['stripe_currency_code']) ? $post['stripe_currency_code'] : '';

        $payment_data['flutterwave_payment_method'] = isset($post['flutterwave_payment_method']) ? '1' : '0';
        $payment_data['flutterwave_public_key'] = isset($post['flutterwave_public_key']) && !empty($post['flutterwave_public_key']) ? $post['flutterwave_public_key'] : '';
        $payment_data['flutterwave_secret_key'] = isset($post['flutterwave_secret_key']) && !empty($post['flutterwave_secret_key']) ? $post['flutterwave_secret_key'] : '';
        $payment_data['flutterwave_encryption_key'] = isset($post['flutterwave_encryption_key']) && !empty($post['flutterwave_encryption_key']) ? $post['flutterwave_encryption_key'] : '';
        $payment_data['flutterwave_currency_code'] = isset($post['flutterwave_currency_code']) && !empty($post['flutterwave_currency_code']) ? $post['flutterwave_currency_code'] : '';

        $payment_data['paytm_payment_method'] = isset($post['paytm_payment_method']) ? '1' : '0';
        $payment_data['paytm_payment_mode'] = isset($post['paytm_payment_mode']) && !empty($post['paytm_payment_mode']) ? $post['paytm_payment_mode'] : '';
        $payment_data['paytm_merchant_key'] = isset($post['paytm_merchant_key']) && !empty($post['paytm_merchant_key']) ? $post['paytm_merchant_key'] : '';
        $payment_data['paytm_merchant_id'] = isset($post['paytm_merchant_id']) && !empty($post['paytm_merchant_id']) ? $post['paytm_merchant_id'] : '';
        $payment_data['paytm_website'] = isset($post['paytm_payment_mode']) && $post['paytm_payment_mode'] == 'production' ? $post['paytm_website'] : 'WEBSTAGING';
        $payment_data['paytm_industry_type_id'] = isset($post['paytm_payment_mode']) && $post['paytm_payment_mode'] == 'production' ? $post['paytm_industry_type_id'] : 'Retail';

        $payment_data['midtrans_payment_mode'] = isset($post['midtrans_payment_mode']) && !empty($post['midtrans_payment_mode']) ? $post['midtrans_payment_mode'] : '';
        $payment_data['midtrans_payment_method'] = isset($post['midtrans_payment_method']) ? '1' : '0';
        $payment_data['midtrans_client_key'] = isset($post['midtrans_client_key']) && !empty($post['midtrans_client_key']) ? $post['midtrans_client_key'] : '';
        $payment_data['midtrans_merchant_id'] = isset($post['midtrans_merchant_id']) && !empty($post['midtrans_merchant_id']) ? $post['midtrans_merchant_id'] : '';
        $payment_data['midtrans_server_key'] = isset($post['midtrans_server_key']) && !empty($post['midtrans_server_key']) ? $post['midtrans_server_key'] : '';

        $payment_data['cod_method'] = isset($post['cod_method']) ? '1' : '0';

        $payment_data = json_encode($payment_data);

        $query = $this->db->get_where('settings', array(
            'variable' => 'payment_method'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'payment_method',
                'value' => $payment_data
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $payment_data)->where('variable', 'payment_method')->update('settings');
        }
    }

    public function update_fcm_details($post)
    {
        $post = escape_array($post);

        $query = $this->db->get_where('settings', array(
            'variable' => 'fcm_server_key'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'fcm_server_key',
                'value' => $post['fcm_server_key']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $post['fcm_server_key'])->where('variable', 'fcm_server_key')->update('settings');
        }
    }

    public function update_contact_details($post)
    {
        $post = escape_array($post);

        $query = $this->db->get_where('settings', array(
            'variable' => 'contact_us'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'contact_us',
                'value' => $post['contact_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $post['contact_input_description'])->where('variable', 'contact_us')->update('settings');
        }
    }

    public function update_privacy_policy($post)
    {
        $post = escape_array($post);

        $query = $this->db->get_where('settings', array(
            'variable' => 'privacy_policy'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'privacy_policy',
                'value' => $post['privacy_policy_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $post['privacy_policy_input_description'])->where('variable', 'privacy_policy')->update('settings');
        }
    }

    public function update_terms_n_condtions($post)
    {
        $post = escape_array($post);

        $query = $this->db->get_where('settings', array(
            'variable' => 'terms_conditions'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'terms_conditions',
                'value' => $post['terms_n_conditions_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $post['terms_n_conditions_input_description'])->where('variable', 'terms_conditions')->update('settings');
        }
    }

    public function update_about_us($post)
    {
        $query = $this->db->get_where('settings', array(
            'variable' => 'about_us'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'about_us',
                'value' => $post['about_us_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $post['about_us_input_description'])->where('variable', 'about_us')->update('settings');
        }
    }

    public function update_email_settings($data)
    {
        $data = escape_array($data);
        $email_data = json_encode($data);
        $query = $this->db->get_where('settings', array(
            'variable' => 'email_settings'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'email_settings',
                'value' => $email_data
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $email_data)->where('variable', 'email_settings')->update('settings');
        }
    }



    public function update_rider_privacy_policy($data)
    {
        $data = escape_array($data);
        $query = $this->db->get_where('settings', array(
            'variable' => 'rider_privacy_policy'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'rider_privacy_policy',
                'value' => $data['privacy_policy_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $data['privacy_policy_input_description'])->where('variable', 'rider_privacy_policy')->update('settings');
        }
    }
    public function update_partner_privacy_policy($data)
    {
        $data = escape_array($data);
        $query = $this->db->get_where('settings', array(
            'variable' => 'partner_privacy_policy'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'partner_privacy_policy',
                'value' => $data['privacy_policy_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $data['privacy_policy_input_description'])->where('variable', 'partner_privacy_policy')->update('settings');
        }
    }

    public function update_rider_terms_n_condtions($data)
    {
        $data = escape_array($data);
        $query = $this->db->get_where('settings', array(
            'variable' => 'rider_terms_conditions'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'rider_terms_conditions',
                'value' => $data['terms_n_conditions_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $data['terms_n_conditions_input_description'])->where('variable', 'rider_terms_conditions')->update('settings');
        }
    }
    public function update_partner_terms_n_condtions($data)
    {
        $data = escape_array($data);
        $query = $this->db->get_where('settings', array(
            'variable' => 'partner_terms_conditions'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'partner_terms_conditions',
                'value' => $data['terms_n_conditions_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $data['terms_n_conditions_input_description'])->where('variable', 'partner_terms_conditions')->update('settings');
        }
    }
    public function update_admin_privacy_policy($data)
    {
        $data = escape_array($data);
        $query = $this->db->get_where('settings', array(
            'variable' => 'admin_privacy_policy'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'admin_privacy_policy',
                'value' => $data['privacy_policy_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $data['privacy_policy_input_description'])->where('variable', 'admin_privacy_policy')->update('settings');
        }
    }

    public function update_admin_terms_n_condtions($data)
    {
        $data = escape_array($data);
        $query = $this->db->get_where('settings', array(
            'variable' => 'admin_terms_conditions'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'admin_terms_conditions',
                'value' => $data['terms_n_conditions_input_description']
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $data['terms_n_conditions_input_description'])->where('variable', 'admin_terms_conditions')->update('settings');
        }
    }

    public function firebase_setting($post)
    {
        $post = escape_array($post);

        $system_data = json_encode($post);
        $query = $this->db->get_where('settings', array(
            'variable' => 'firebase_settings'
        ));
        $count = $query->num_rows();
        if ($count === 0) {
            $data = array(
                'variable' => 'firebase_settings',
                'value' => $system_data
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $system_data)->where('variable', 'firebase_settings')->update('settings');
        }
    }

    public function update_web_setting($post)
    {
        $post = escape_array($post);
        $post['app_download_section'] = (isset($post['app_download_section']) && !empty($post['app_download_section'])) ?: 0;
        $post['shipping_mode'] = (isset($post['shipping_mode']) && !empty($post['shipping_mode'])) ?: 0;
        $post['return_mode'] = (isset($post['return_mode']) && !empty($post['return_mode'])) ?: 0;
        $post['support_mode'] = (isset($post['support_mode']) && !empty($post['support_mode'])) ?: 0;
        $post['safety_security_mode'] = (isset($post['safety_security_mode']) && !empty($post['safety_security_mode'])) ?: 0;
        $main_image_name = (isset($post['logo']) && !empty($post['logo'])) ? $post['logo'] : "";
        $light_image_name = (isset($post['light_logo']) && !empty($post['light_logo'])) ? $post['light_logo'] : "";
        $favicon_image_name = (isset($post['favicon']) && !empty($post['favicon'])) ? $post['favicon'] : "";
        $system_data = json_encode($post);
        $query = $this->db->get_where('settings', array(
            'variable' => 'web_settings'
        ));
        $count = $query->num_rows();
        if ($main_image_name != NULL && !empty($main_image_name)) {
            $logo_res = $this->db->get_where('settings', array(
                'variable' => 'web_logo'
            ));
            $logo_count = $logo_res->num_rows();
            if ($logo_count == 0) {
                $this->db->insert('settings', ['value' => $main_image_name, 'variable' => 'web_logo']);
            } else {
                $this->db->set('value', $main_image_name)->where('variable', 'web_logo')->update('settings');
            }
        }
        if ($light_image_name != NULL && !empty($light_image_name)) {
            $logo_res = $this->db->get_where('settings', array(
                'variable' => 'light_logo'
            ));
            $logo_count = $logo_res->num_rows();
            if ($logo_count == 0) {
                $this->db->insert('settings', ['value' => $light_image_name, 'variable' => 'light_logo']);
            } else {
                $this->db->set('value', $light_image_name)->where('variable', 'light_logo')->update('settings');
            }
        }
        if ($favicon_image_name != NULL && !empty($favicon_image_name)) {
            $favicon_res = $this->db->get_where('settings', array(
                'variable' => 'web_favicon'
            ));
            $favicon_count = $favicon_res->num_rows();
            if ($favicon_count == 0) {
                $this->db->insert('settings', ['value' => $favicon_image_name, 'variable' => 'web_favicon']);
            } else {
                $this->db->set('value', $favicon_image_name)->where('variable', 'web_favicon')->update('settings');
            }
        }
        if ($count === 0) {
            $data = array(
                'variable' => 'web_settings',
                'value' => $system_data
            );
            $this->db->insert('settings', $data);
        } else {
            $this->db->set('value', $system_data)->where('variable', 'web_settings')->update('settings');
        }
    }
}
