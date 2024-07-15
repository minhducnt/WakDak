<?php

defined('BASEPATH') or exit('No direct script access allowed');

class Cron_job extends CI_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->database();
        $this->load->library(['ion_auth', 'form_validation', 'upload']);
        $this->load->helper(['url', 'language', 'file']);
        $this->load->model(['Partner_model']);
    }

    public function settle_partner_commission()
    {
        return $this->Partner_model->settle_partner_commission();
    }
    public function settle_admin_commission()
    {
        return $this->Partner_model->settle_admin_commission();
    }
    public function settle_payment()
    {
        // echo "hello";
        $currency = get_settings('currency');
        // echo "<pre>";

        $row = $this->db->select('*')->where('payment_method', 'PayPal')->or_where('payment_method', 'midtrans')->get('orders')->result_array();

        foreach ($row as $order_details) {
            // echo "<pre>";
            // print_r($order_details);

            $transaction = $this->db->select('*')->where('order_id', $order_details['id'])->get('transactions')->result_array();
            if (empty($transaction)) {
                $user_res = fetch_details(['id' => $order_details['user_id']], 'users', 'fcm_id');
                // echo "<pre>";
                // print_r($user_res);
                $fcm_ids = array();
                if (!empty($user_res[0]['fcm_id'])) {
                    $fcm_ids[0][] = $user_res[0]['fcm_id'];
                }
                $wallet_balance = $order_details['wallet_balance'];
                $user_id = $order_details['user_id'];
                if ($wallet_balance != 0) {
                    /* update user's wallet */
                    $returnable_amount = $wallet_balance;
                    // print_R($returnable_amount);
                    // return false;
                    $fcmMsg = array(
                        'title' => "Amount Credited To Wallet",
                        'body' => $currency . ' ' . $returnable_amount,
                        'type' => "wallet"
                    );
                    send_notification($fcmMsg, $fcm_ids);
                    $re =  update_wallet_balance('credit', $user_id, $returnable_amount, 'Wallet Amount Credited for Order Item ID  : ' . $order_details['id']);

                    delete_details(['id' => $order_details['id']], 'orders');
                    delete_details(['order_id' => $order_details['id']], 'order_items');
                }
            }
        }
    }
}
