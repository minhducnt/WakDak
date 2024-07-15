<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Branch extends CI_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->database();
        $this->load->helper(['url', 'language', 'timezone_helper']);
        $this->load->model('Branch_model');
        if (!has_permissions('read', 'tags')) {
            $this->session->set_flashdata('authorize_flag', PERMISSION_ERROR_MSG);
            redirect('admin/home', 'refresh');
        }
    }

    public function index()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {
            $this->data['main_page'] = FORMS . 'Branch';
            $settings = get_settings('system_settings', true);
            // $this->data['title'] = 'Add Branch | ' . $settings['app_name'];
            // $this->data['meta_description'] = 'Add Branch | ' . $settings['app_name'];
            // if (isset($_GET['edit_branch'])) {
            //     $this->data['fetched_data'] = fetch_details(['id' => $_GET['edit_branch']], 'branch');
            // }

            if (isset($_GET['edit_branch'])) {

                $this->data['title'] = 'Update Branch | ' . $settings['app_name'];
                $this->data['meta_description'] = 'Update Branch | ' . $settings['app_name'];
                $this->data['fetched_details'] = fetch_details(['id' => $_GET['edit_branch']], 'branch');
                // print_r($this->data['fetched_details']);
                // return;
            } else {
                $this->data['title'] = 'Add Branch | ' . $settings['app_name'];
                $this->data['meta_description'] = 'Add Branch | ' . $settings['app_name'];
            }
            $this->load->view('admin/template', $this->data);
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function manage_branch()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {
            $this->data['main_page'] = TABLES . 'manage-branch';
            $settings = get_settings('system_settings', true);
            $this->data['title'] = 'Manage Branch | ' . $settings['app_name'];
            $this->data['meta_description'] = 'Manage Branch  | ' . $settings['app_name'];
            if (!isset($_SESSION['branch_id'])) {

                redirect('admin/branch', 'refresh');
            } else {

                $this->load->view('admin/template', $this->data);
            }
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function add_branch()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {

            if (isset($_POST['edit_branch'])) {

                if (print_msg(!has_permissions('update', 'branch'), PERMISSION_ERROR_MSG, 'branch')) {
                    return false;
                }
            } else {
                if (print_msg(!has_permissions('create', 'branch'), PERMISSION_ERROR_MSG, 'branch')) {
                    return false;
                }
            }
            // echo "<pre>";
            // print_r($_POST);


            $this->form_validation->set_rules('branch_name', 'Branch Name', 'trim|required|xss_clean');
            $this->form_validation->set_rules('description', 'Description', 'trim|xss_clean');
            $this->form_validation->set_rules('address', 'Address', 'trim|required|xss_clean');
            $this->form_validation->set_rules('city', 'City', 'trim|required|xss_clean');
            $this->form_validation->set_rules('latitude', 'Latitude', 'trim|required|xss_clean');
            $this->form_validation->set_rules('longitude', 'Longitude', 'trim|required|xss_clean');
            $this->form_validation->set_rules('email', 'Email', 'trim|required|xss_clean');
            $this->form_validation->set_rules('contact', 'Contact', 'trim|required|xss_clean');
            $this->form_validation->set_rules('status', 'Status', 'trim|required|xss_clean');
            if (isset($_POST['edit_branch'])) {
                $this->form_validation->set_rules('working_time', 'Working Days', 'trim|xss_clean');
            } else {

                $this->form_validation->set_rules('working_time', 'Working Days', 'trim|xss_clean|required');
            }

            if (!$this->form_validation->run()) {
                $this->response['error'] = true;
                $this->response['csrfName'] = $this->security->get_csrf_token_name();
                $this->response['csrfHash'] = $this->security->get_csrf_hash();
                $this->response['message'] = validation_errors();
                print_r(json_encode($this->response));
            } else {
                if (isset($_POST['edit_branch'])) {
                    if (is_exist(['branch_name' => $this->input->post('branch_name', true)], 'branch', $this->input->post('edit_branch', true))) {
                        $response["error"]   = true;
                        $response['csrfName'] = $this->security->get_csrf_token_name();
                        $response['csrfHash'] = $this->security->get_csrf_hash();
                        $response["message"] = "This Branch Already Exist.";
                        $response["data"] = array();
                        echo json_encode($response);
                        return false;
                    }
                } else {
                    if (is_exist(['branch_name' => $this->input->post('branch_name', true)], 'branch')) {
                        $response["error"]   = true;
                        $response['csrfName'] = $this->security->get_csrf_token_name();
                        $response['csrfHash'] = $this->security->get_csrf_hash();
                        $response["message"] = "This Branch Already Exist.";
                        $response["data"] = array();
                        echo json_encode($response);
                        return false;
                    }
                }
                $self_pickup = isset($_POST['self_pickup']) && $_POST['self_pickup'] == 'on' ? 1 : 0;
                $deliver_orders = isset($_POST['deliver_orders']) && $_POST['deliver_orders'] == 'on' ? 1 : 0;


                if ($self_pickup == 0 && $deliver_orders == 0) {
                    $response["error"]   = true;
                    $response['csrfName'] = $this->security->get_csrf_token_name();
                    $response['csrfHash'] = $this->security->get_csrf_hash();
                    $response["message"] = "You have to enable at least one delivery option form self pickup and deliver order.";
                    $response["data"] = array();
                    echo json_encode($response);
                    return false;
                }
                // if (isset($_POST['working_time'])) {

                $working_time = $_POST['working_time'];
                // } else {

                //     if (isset($_POST['edit_branch'])) {
                //         $test = fetch_details(['id' => $_POST['edit_branch']], 'branch', '*');
                //         echo "<pre>";
                //         print_r($test);
                //         die;
                //     }
                // }

                $this->Branch_model->add_branch($_POST, $working_time);
                $this->response['error'] = false;
                $this->response['csrfName'] = $this->security->get_csrf_token_name();
                $this->response['csrfHash'] = $this->security->get_csrf_hash();
                $message = (isset($_POST['edit_branch'])) ? 'Branch Updated Successfully' : 'Branch Added Successfully';
                $this->response['message'] = $message;
                print_r(json_encode($this->response));
            }
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function branch_list()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {
            return $this->Branch_model->get_branch_list();
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function delete_branch()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {

            if (defined('ALLOW_MODIFICATION') && ALLOW_MODIFICATION == 0) {
                $this->response['error'] = true;
                $this->response['message'] = DEMO_VERSION_MSG;
                echo json_encode($this->response);
                return false;
                exit();
            }
            $branch_id = $this->input->get('id', true);

            // if (is_exist(['tag_id' => $tag_id], 'product_tags')) {
            //     delete_details(['tag_id' => $tag_id], 'product_tags');
            // }
            if (delete_details(['id' => $branch_id], 'branch') == TRUE) {
                $this->response['error'] = false;
                $this->response['message'] = 'Deleted Succesfully';
            } else {
                $this->response['error'] = true;
                $this->response['message'] = 'Something Went Wrong';
            }
            print_r(json_encode($this->response));
        } else {
            redirect('admin/login', 'refresh');
        }
    }

    public function save_branch($data = NULL)
    {
        // print_r($_POST);
        session_start();

        if (isset($_POST['id'])) {
            $id = $_POST['id'];
            $_SESSION['branch_id'] = $id;

            echo "ID stored in session successfully.";
        } else {
            echo "Error: ID not received.";
        }
    }

    public function get_branch()
    {
        if ($this->ion_auth->logged_in() && $this->ion_auth->is_admin()) {

            $limit = (isset($_GET['limit'])) ? $this->input->get('limit', true) : 25;
            $offset = (isset($_GET['offset'])) ? $this->input->get('offset', true) : 0;
            $search =  (isset($_GET['search'])) ? $_GET['search'] : null;
            $tags = $this->Branch_model->get_branch($search, $limit, $offset);
            $this->response['data'] = $tags;
            $this->response['csrfName'] = $this->security->get_csrf_token_name();
            $this->response['csrfHash'] = $this->security->get_csrf_hash();
            print_r(json_encode($this->response));
        } else {
            redirect('admin/login', 'refresh');
        }
    }
}
