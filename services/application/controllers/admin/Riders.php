<?php

defined('BASEPATH') or exit('No direct script access allowed');

class Riders extends CI_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->database();
        $this->load->library(['ion_auth', 'form_validation', 'upload']);
        $this->load->helper(['url', 'language', 'file']);
        $this->load->model(['Rider_model', 'rating_model']);
        if (!has_permissions('read', 'rider')) {
            $this->session->set_flashdata('authorize_flag', PERMISSION_ERROR_MSG);
            redirect('admin/home', 'refresh');
        }
    }

    public function index()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {
            $this->data['main_page'] = FORMS . 'rider';
            $settings = get_settings('system_settings', true);
            $this->data['title'] = 'Add Rider | ' . $settings['app_name'];
            $this->data['meta_description'] = 'Add Rider  | ' . $settings['app_name'];
            if (isset($_GET['edit_id']) && !empty($_GET['edit_id'])) {
                $this->data['fetched_data'] = $this->db->select(' u.* ')
                    ->join('users_groups ug', ' ug.user_id = u.id ')
                    ->where(['ug.group_id' => '3', 'ug.user_id' => $_GET['edit_id']])
                    ->get('users u')
                    ->result_array();
            }
            $this->data['currency'] = get_settings('currency');
            if (!isset($_SESSION['branch_id'])) {

                redirect('admin/branch', 'refresh');
            } else {

                $this->load->view('admin/template', $this->data);
            }
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function manage_rider()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {
            $this->data['main_page'] = TABLES . 'manage-rider';
            $settings = get_settings('system_settings', true);
            $this->data['title'] = 'Rider Management | ' . $settings['app_name'];
            $this->data['meta_description'] = 'Rider Management  | ' . $settings['app_name'];
            $this->data['currency'] = get_settings('currency');
            if (!isset($_SESSION['branch_id'])) {

                redirect('admin/branch', 'refresh');
            } else {

                $this->load->view('admin/template', $this->data);
            }
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function view_riders()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {

            return $this->Rider_model->get_riders_list();
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function delete_riders()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {

            if (print_msg(!has_permissions('delete', 'rider'), PERMISSION_ERROR_MSG, 'rider', false)) {
                return true;
            }

            if (delete_details(['id' => $_GET['id']], 'users') == TRUE) {
                if (delete_details(['user_id' => $_GET['id']], 'users_groups') == TRUE) {
                    $this->response['error'] = false;
                    $this->response['message'] = 'User removed from Rider succesfully';
                    print_r(json_encode($this->response));
                }
            }

            // if (update_details(['group_id' => '2'], ['user_id' => $_GET['id'], 'group_id' => 3], 'users_groups') == TRUE) {
            //     $this->response['error'] = false;
            //     $this->response['message'] = 'User removed from Rider succesfully';
            //     print_r(json_encode($this->response));
            // } 
            else {
                $this->response['error'] = true;
                $this->response['message'] = 'Something Went Wrong';
                print_r(json_encode($this->response));
            }
        } else {
            redirect('admin/login', 'refresh');
        }
    }


    public function add_rider()
    {
        // print_R($_FILES);
        // return false;
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {

            if (isset($_POST['edit_rider'])) {
                if (print_msg(!has_permissions('update', 'rider'), PERMISSION_ERROR_MSG, 'rider')) {
                    return true;
                }
            } else {
                if (print_msg(!has_permissions('create', 'rider'), PERMISSION_ERROR_MSG, 'rider')) {
                    return true;
                }
            }

            $this->form_validation->set_rules('name', 'Name', 'trim|required|xss_clean');
            $this->form_validation->set_rules('email', 'Mail', 'trim|required|xss_clean');
            $this->form_validation->set_rules('mobile', 'Mobile', 'trim|required|xss_clean|min_length[5]');
            $this->form_validation->set_rules('profile', 'Rider Profile', 'trim|xss_clean');
            if (!isset($_POST['edit_rider'])) {
                $this->form_validation->set_rules('profile', 'Rider Profile', 'trim|xss_clean');
                $this->form_validation->set_rules('password', 'Password', 'trim|required|xss_clean');
                $this->form_validation->set_rules('confirm_password', 'Confirm password', 'trim|required|matches[password]|xss_clean');
            }
            $this->form_validation->set_rules('address', 'Address', 'trim|required|xss_clean');
            $this->form_validation->set_rules('serviceable_city', 'Serviceable city', 'trim|required|xss_clean');
            $this->form_validation->set_rules('active', 'Status', 'trim|xss_clean');
            $this->form_validation->set_rules('commission_method', 'Commission Method', 'trim|required|xss_clean');
            if (isset($_POST['commission_method']) && !empty($_POST['commission_method']) && $_POST['commission_method'] == "percentage_on_delivery_charges") {
                $this->form_validation->set_rules('percentage', 'Percentage', 'trim|xss_clean|required');
            }
            if (isset($_POST['commission_method']) && !empty($_POST['commission_method']) && $_POST['commission_method'] == "fixed_commission_per_order") {
                $this->form_validation->set_rules('commission', 'Commission', 'trim|xss_clean|required');
            }
            if (!$this->form_validation->run()) {

                $this->response['error'] = true;
                $this->response['csrfName'] = $this->security->get_csrf_token_name();
                $this->response['csrfHash'] = $this->security->get_csrf_hash();
                $this->response['message'] = validation_errors();
                print_r(json_encode($this->response));
            } else {
                // profile image

                if (isset($_POST['commission']) && !empty($_POST['commission'])) {
                } else {

                    if (isset($_POST['percentage']) && !empty($_POST['percentage'])) {

                        if ($_POST['percentage'] <= 0 || $_POST['percentage'] > 100) {
                            $response["error"]   = true;
                            $response["message"] = "Percentage on Delivery Charges is not valid";
                            $response['csrfName'] = $this->security->get_csrf_token_name();
                            $response['csrfHash'] = $this->security->get_csrf_hash();
                            $response["data"] = array();
                            echo json_encode($response);
                            return false;
                        }
                    }
                }

                $temp_array_logo = $profile_doc = array();
                $logo_files = $_FILES;
                $profile_error = "";
                $config = [
                    'upload_path' =>  FCPATH . USER_IMG_PATH,
                    'allowed_types' => 'jpg|png|jpeg|gif',
                    'max_size' => 8000,
                ];
                if (isset($logo_files['profile']) && !empty($logo_files['profile']['name']) && isset($logo_files['profile']['name'])) {
                    $other_img = $this->upload;
                    // print_R($other_img);
                    $other_img->initialize($config);

                    if (isset($_POST['edit_rider']) && !empty($_POST['edit_rider']) && isset($_POST['profile']) && !empty($_POST['profile'])) {
                        $old_logo = explode('/', $this->input->post('profile', true));
                        delete_images(USER_IMG_PATH, $old_logo[2]);
                    }

                    if (!empty($logo_files['profile']['name'])) {

                        $_FILES['temp_image']['name'] = $logo_files['profile']['name'];
                        $_FILES['temp_image']['type'] = $logo_files['profile']['type'];
                        $_FILES['temp_image']['tmp_name'] = $logo_files['profile']['tmp_name'];
                        $_FILES['temp_image']['error'] = $logo_files['profile']['error'];
                        $_FILES['temp_image']['size'] = $logo_files['profile']['size'];
                        if (!$other_img->do_upload('temp_image')) {
                            $profile_error = 'Images :' . $profile_error . ' ' . $other_img->display_errors();
                        } else {
                            $temp_array_logo = $other_img->data();
                            resize_review_images($temp_array_logo, FCPATH . USER_IMG_PATH);
                            $profile_doc  = USER_IMG_PATH . $temp_array_logo['file_name'];
                        }
                    } else {
                        $_FILES['temp_image']['name'] = $logo_files['profile']['name'];
                        $_FILES['temp_image']['type'] = $logo_files['profile']['type'];
                        $_FILES['temp_image']['tmp_name'] = $logo_files['profile']['tmp_name'];
                        $_FILES['temp_image']['error'] = $logo_files['profile']['error'];
                        $_FILES['temp_image']['size'] = $logo_files['profile']['size'];
                        if (!$other_img->do_upload('temp_image')) {
                            $profile_error = $other_img->display_errors();
                        }
                    }
                    //Deleting Uploaded Images if any overall error occured
                }

                if ($profile_error != NULL) {
                    $this->response['error'] = true;
                    $this->response['csrfName'] = $this->security->get_csrf_token_name();
                    $this->response['csrfHash'] = $this->security->get_csrf_hash();
                    $this->response['message'] =  $profile_error;
                    print_r(json_encode($this->response));
                    return;
                }
                /* process commission params */
                $commission_method = $this->input->post("commission_method", true);
                $commission = 0;
                if (isset($commission_method) && !empty($commission_method) && $commission_method == "percentage_on_delivery_charges") {
                    $commission = $this->input->post("percentage");
                }
                if (isset($commission_method) && !empty($commission_method) && $commission_method == "fixed_commission_per_order") {
                    $commission = $this->input->post("commission");
                }

                $_POST['commission'] = $commission;
                $_POST['percentage'] = $this->input->post("percentage", true);

                if (isset($_POST['edit_rider'])) {
                    // print_r($_POST);
                    if ($_POST['commission_method'] == 'percentage_on_delivery_charges') {
                        if (isset($_POST['percentage']) && !empty($_POST['percentage'])) {

                            if ($_POST['percentage'] <= 0 || $_POST['percentage'] > 100) {
                                $response["error"]   = true;
                                $response["message"] = "Percentage on Delivery Charges is not valid";
                                $response['csrfName'] = $this->security->get_csrf_token_name();
                                $response['csrfHash'] = $this->security->get_csrf_hash();
                                $response["data"] = array();
                                echo json_encode($response);
                                return false;
                            }
                        }
                    }
                    // if (isset($_POST['commission']) && !empty($_POST['commission'])) {
                    // } else {


                    // }
                    // die;
                    if (!edit_unique($this->input->post('email', true), 'users.email.' . $this->input->post('edit_rider', true) . '') || !edit_unique($this->input->post('mobile', true), 'users.mobile.' . $this->input->post('edit_rider', true) . '')) {
                        $response["error"]   = true;
                        $response["message"] = "Email or mobile already exists !";
                        $response['csrfName'] = $this->security->get_csrf_token_name();
                        $response['csrfHash'] = $this->security->get_csrf_hash();
                        $response["data"] = array();
                        echo json_encode($response);
                        return false;
                    }
                    // print_R($_FILES);
                    $_POST['serviceable_city'] = $this->input->post('serviceable_city', true);
                    $_POST['active'] = $this->input->post("active", true);
                    $_POST['rider_cancel_order'] = isset($_POST['rider_cancel_order']) && $_POST['rider_cancel_order'] == 'on' ? 1 : 0;
                    $image = USER_IMG_PATH . $_FILES['profile']['name'];

                    $this->Rider_model->update_rider($_POST, $image);
                } else {
                    // print_r($_SESSION['branch_id']);
                    // return;
                    if (!$this->form_validation->is_unique($_POST['mobile'], 'users.mobile') || !$this->form_validation->is_unique($_POST['email'], 'users.email')) {
                        $response["error"]   = true;
                        $response["message"] = "Email or mobile already exists !";
                        $response['csrfName'] = $this->security->get_csrf_token_name();
                        $response['csrfHash'] = $this->security->get_csrf_hash();
                        $response["data"] = array();
                        echo json_encode($response);
                        return false;
                    }

                    $identity_column = $this->config->item('identity', 'ion_auth');
                    $email = strtolower($this->input->post('email'));
                    $mobile = $this->input->post('mobile');
                    $identity = ($identity_column == 'mobile') ? $mobile : $email;
                    $password = $this->input->post('password');
                    $branch_id = isset($_SESSION['branch_id']) ? $_SESSION['branch_id'] : "";

                    if (validatePassword($password)) {
                        $additional_data = [
                            'username' => $this->input->post('name'),
                            'address' => $this->input->post('address'),
                            'serviceable_city' => $this->input->post('serviceable_city', true),
                            'commission_method' => $commission_method,
                            'commission' => $commission,
                            'branch_id' => $branch_id,
                            'image' => (!empty($profile_doc)) ? $profile_doc : $this->input->post('profile', true),
                            'rider_cancel_order' => isset($_POST['rider_cancel_order']) && $_POST['rider_cancel_order'] == 'on' ? 1 : 0,
                        ];
                        $this->ion_auth->register($identity, $password, $email, $additional_data, ['3']);
                        update_details(['active' => 1], [$identity_column => $identity], 'users');
                    } else {
                        $response["error"]   = true;
                        $response["message"] = "Password Should be atleast 8 character, one upparcase letter, one lowercase letter and one number!";
                        $response['csrfName'] = $this->security->get_csrf_token_name();
                        $response['csrfHash'] = $this->security->get_csrf_hash();
                        $response["data"] = array();
                        echo json_encode($response);
                        return false;
                    }
                }

                $this->response['error'] = false;
                $this->response['csrfName'] = $this->security->get_csrf_token_name();
                $this->response['csrfHash'] = $this->security->get_csrf_hash();
                $message = (isset($_POST['edit_rider'])) ? 'Rider Update Successfully' : 'Rider Added Successfully';
                $this->response['message'] = $message;
                print_r(json_encode($this->response));
            }
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function get_rating_list()
    {

        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {

            return $this->rating_model->get_rider_rating();
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function manage_cash()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {
            $this->data['main_page'] = TABLES . 'cash-collection';
            $settings = get_settings('system_settings', true);
            $this->data['curreny'] = $settings['currency'];
            $this->data['riders'] = $this->db->where(['ug.group_id' => '3', 'u.active' => 1])->join('users_groups ug', 'ug.user_id = u.id')->get('users u')->result_array();
            $this->data['title'] = 'View Cash Collection | ' . $settings['app_name'];
            $this->data['meta_description'] = ' View Cash Collection  | ' . $settings['app_name'];
            if (!isset($_SESSION['branch_id'])) {

                redirect('admin/branch', 'refresh');
            } else {

                $this->load->view('admin/template', $this->data);
            }
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function get_cash_collection()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {
            return $this->Rider_model->get_cash_collection_list();
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function manage_cash_collection()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {
            if (print_msg(!has_permissions('create', 'fund_transfer'), PERMISSION_ERROR_MSG, 'fund_transfer')) {
                return false;
            }

            $this->form_validation->set_rules('rider_id', 'Rider', 'trim|required|xss_clean|numeric');
            $this->form_validation->set_rules('amount', 'Amount', 'trim|required|xss_clean|numeric|greater_than[0]');
            $this->form_validation->set_rules('date', 'Date', 'trim|required|xss_clean');
            $this->form_validation->set_rules('message', 'Message', 'trim|xss_clean');
            if (!$this->form_validation->run()) {
                $this->response['error'] = true;
                $this->response['csrfName'] = $this->security->get_csrf_token_name();
                $this->response['csrfHash'] = $this->security->get_csrf_hash();
                $this->response['message'] = validation_errors();
                echo json_encode($this->response);
                return false;
            } else {
                $rider_id = $this->input->post('rider_id', true);
                if (!is_exist(['id' => $rider_id], 'users')) {
                    $this->response['error'] = true;
                    $this->response['message'] = 'Rider is not exist in your database';
                    $this->response['csrfName'] = $this->security->get_csrf_token_name();
                    $this->response['csrfHash'] = $this->security->get_csrf_hash();
                    print_r(json_encode($this->response));
                    return false;
                }
                $res = fetch_details(['id' => $rider_id], 'users', 'cash_received');
                $amount = $this->input->post('amount', true);
                $date = $this->input->post('date', true);
                $message = (isset($_POST['message']) && !empty($_POST['message'])) ? $this->input->post('message', true) : "Rider cash collection by admin";

                if ($res[0]['cash_received'] < $amount) {
                    $this->response['error'] = true;
                    $this->response['csrfName'] = $this->security->get_csrf_token_name();
                    $this->response['csrfHash'] = $this->security->get_csrf_hash();
                    $this->response['message'] = 'Amount must be not be greater than cash';
                    echo json_encode($this->response);
                    return false;
                }

                if ($res[0]['cash_received'] > 0 && $res[0]['cash_received'] != null) {
                    update_cash_received($amount, $rider_id, "deduct");
                    $this->load->model("transaction_model");
                    $transaction_data = [
                        'transaction_type' => "transaction",
                        'user_id' => $rider_id,
                        'order_id' => "",
                        'type' => "rider_cash_collection",
                        'txn_id' => "",
                        'amount' => $amount,
                        'status' => "1",
                        'message' => $message,
                        'transaction_date' => $date,
                    ];
                    $this->transaction_model->add_transaction($transaction_data);
                    $this->response['error'] = false;
                    $this->response['csrfName'] = $this->security->get_csrf_token_name();
                    $this->response['csrfHash'] = $this->security->get_csrf_hash();
                    $this->response['message'] = 'Amount Successfully Collected';
                } else {
                    $this->response['error'] = true;
                    $this->response['csrfName'] = $this->security->get_csrf_token_name();
                    $this->response['csrfHash'] = $this->security->get_csrf_hash();
                    $this->response['message'] = 'Cash should be greater than 0';
                }

                echo json_encode($this->response);
                return false;
            }
        } else {
            redirect('admin/login', 'refresh');
        }
    }
}
