<?php

defined('BASEPATH') or exit('No direct script access allowed');
class Offer_model extends CI_Model
{

    public function __construct()
    {
        parent::__construct();
        $this->load->database();
        $this->load->library(['ion_auth', 'form_validation']);
        $this->load->helper(['url', 'language', 'function_helper']);
    }

    function add_offer($image_name)
    {
        // print_r($image_name);
        // die;
        $image_name = escape_array($image_name);
        $offer_data = [
            'type' => $image_name['offer_type'],
            'image' => $image_name['image'],
        ];
        if (isset($image_name['offer_type']) && $image_name['offer_type'] == 'categories' && isset($image_name['category_id']) && !empty($image_name['category_id'])) {
            $offer_data['type_id'] = $image_name['category_id'];
        }

        if (isset($image_name['offer_type']) && $image_name['offer_type'] == 'products' && isset($image_name['product_id']) && !empty($image_name['product_id'])) {
            $offer_data['type_id'] = $image_name['product_id'];
        }
        // if (isset($image_name['banner'])) {
        //     $offer_data['banner'] = (isset($image_name['banner']) && !empty($image_name['banner'])) ? $image_name['banner'] : '';
        // }
        if (isset($image_name['edit_offer'])) {
            if (empty($image_name['image'])) {
                unset($offer_data['image']);
            }
            // $offer_data['banner'] = (isset($offer_data['banner'])) ? $offer_data['banner'] : '';
            $this->db->set($offer_data)->where('id', $image_name['edit_offer'])->update('offers');
        } else {
            $branch_ids = array($_SESSION['branch_id']);
            for ($i = 0; $i < count($branch_ids); $i++) {
                $offer_data['branch_id'] = $branch_ids[$i];
                $this->db->insert('offers', $offer_data);
            }
        }
    }

    function get_offer_list()
    {

        $offset = 0;
        $limit = 10;
        $sort = 'id';
        $order = 'ASC';
        $multipleWhere = '';


        if (isset($_GET['offset']))
            $offset = $_GET['offset'];
        if (isset($_GET['limit']))
            $limit = $_GET['limit'];

        if (isset($_GET['sort']))
            if ($_GET['sort'] == 'id') {
                $sort = "id";
            } else {
                $sort = $_GET['sort'];
            }
        if (isset($_GET['order']))
            $order = $_GET['order'];

        if (isset($_GET['search']) and $_GET['search'] != '') {
            $search = $_GET['search'];
            $multipleWhere = ['`id`' => $search];
        }
        $branch_id = isset($_SESSION['branch_id'])   ? $_SESSION['branch_id'] : "";
        $where = array('offers.branch_id' => trim($branch_id));
        $count_res = $this->db->select(' COUNT(id) as `total` ');

        if (isset($multipleWhere) && !empty($multipleWhere)) {
            $count_res->or_like($multipleWhere);
        }
        if (isset($where) && !empty($where)) {
            $count_res->where($where);
        }

        $offer_count = $count_res->get('offers')->result_array();

        foreach ($offer_count as $row) {
            $total = $row['total'];
        }

        $search_res = $this->db->select(' * ');
        if (isset($multipleWhere) && !empty($multipleWhere)) {
            $search_res->or_like($multipleWhere);
        }
        if (isset($where) && !empty($where)) {
            $search_res->where($where);
        }

        $offer_search_res = $search_res->order_by($sort, "asc")->limit($limit, $offset)->get('offers')->result_array();

        $bulkData = array();
        $bulkData['total'] = $total;
        $rows = array();
        $tempRow = array();

        foreach ($offer_search_res as $row) {
            // $row = output_escaping($row);
            // print_r($row);
            // die;
            $operate = ' <a href="' . base_url('admin/offer?edit_id=' . $row['id']) . '" class="btn btn-success btn-xs mr-1 mb-1"  title="Edit" data-id="' . $row['id'] . '" data-url="admin/offer/"><i class="fa fa-pen"></i></a>';
            $operate .= ' <a href="javaScript:void(0)" id="delete-offer" class="btn btn-danger btn-xs mr-1 mb-1" title="Delete" data-id="' . $row['id'] . '"><i class="fa fa-trash"></i></a>';

            $tempRow['id'] = $row['id'];
            $tempRow['type'] = $row['type'];
            $tempRow['type_id'] = $row['type_id'];
            $branch_name =  fetch_details(['id' => $row['branch_id']], 'branch', 'branch_name');
            $tempRow['branch'] = $branch_name[0]['branch_name'];
            if (empty($row['image']) || file_exists(FCPATH . $row['image']) == FALSE) {
                $row['image'] = base_url() . NO_IMAGE;
                $row['image_main'] = base_url() . NO_IMAGE;
            } else {
                $row['image_main'] = base_url($row['image']);
                $row['image'] = get_image_url($row['image'], 'thumb', 'sm');
            }
            if (empty($row['banner']) || file_exists(FCPATH . $row['banner']) == FALSE) {
                $row['banner'] = base_url() . NO_IMAGE;
                $row['banner'] = base_url() . NO_IMAGE;
            } else {
                $row['banner'] = get_image_url($row['banner'], 'thumb', 'sm');
            }
            $tempRow['image'] = "<div class='image-container'><a href='" . $row['image_main'] . "' data-toggle='lightbox' data-gallery='gallery'> <img src='" . $row['image'] . "' class='img-fixed-size' ></a></div>";
            $tempRow['banner'] = "<div class='image-container'><a href='" . $row['banner'] . "' data-toggle='lightbox' data-gallery='gallery'> <img src='" . $row['banner'] . "' class='img-fixed-size' ></a></div>";

            $tempRow['date_added'] = $row['date_added'];
            $tempRow['operate'] = $operate;
            $rows[] = $tempRow;
        }
        $bulkData['rows'] = $rows;
        print_r(json_encode($bulkData));
    }
}
