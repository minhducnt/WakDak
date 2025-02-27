<div class="content-wrapper">
    <!-- Content Header (Page header) -->
    <!-- Main content -->
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h4>Payment Request</h4>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a class="text text-info" href="<?= base_url('admin/home') ?>">Home</a></li>
                        <li class="breadcrumb-item active">Payment Request</li>
                    </ol>
                </div>

            </div>
        </div><!-- /.container-fluid -->
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                <div class="modal fade" tabindex="-1" role="dialog" aria-hidden="true" id="payment_request_modal">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">Update Payment Request</h5>
                                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                            <div class="modal-body">
                                <form class="form-horizontal form-submit-event" action="<?= base_url('admin/payment-request/update-payment-request'); ?>" method="POST" enctype="multipart/form-data">
                                    <input type="hidden" name="payment_request_id" id="payment_request_id">
                                    <div class="form-group">
                                        <label class="control-label col-md-3 col-sm-3 col-xs-12">Status <span class='text-danger text-sm'>*</span></label>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <div id="status" class="btn-group">
                                                <label class="btn btn-warning" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                                    <input type="radio" name="status" value="0" class='pending'> Pending
                                                </label>
                                                <label class="btn btn-primary" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                                    <input type="radio" name="status" value="1" class='approved'> Approved
                                                </label>
                                                <label class="btn btn-danger" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                                    <input type="radio" name="status" value="2" class='rejected'> Rejected
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label class="" for="">Remark</label>
                                        <textarea id="update_remarks" name="update_remarks" class="form-control col-12 "></textarea>
                                    </div>
                                    <input type="hidden" id="id" name="id">
                                    <div class="ln_solid"></div>
                                    <div class="form-group">
                                        <button type="reset" class="btn btn-warning">Reset</button>
                                        <button type="submit" class="btn btn-success" id="submit_btn">Update</button>
                                    </div>
                                    <div class="d-flex justify-content-center">
                                        <div class="form-group" id="error_box">
                                        </div>
                                    </div>
                            </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-12 main-content">
            <div class="card content-area p-4">
                <div class="card-innr">
                    <div class="row">
                        <div class="col-md-3">
                            <label for="label" class="col-form-label">Filter By User</label>
                            <select class='form-control' name='user_filter' id="user_filter">
                                <option value=''>Select User</option>
                                <!-- <option value='partner'>Partner</option> -->
                                <option value='rider'>Rider</option>
                            </select>
                        </div>
                    </div>
                    <div class="gaps-1-5x"></div>
                    <table class='table-striped' id='payment_request_table' data-toggle="table" data-url="<?= base_url('admin/payment-request/view-payment-request-list') ?>" data-click-to-select="true" data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true" data-show-refresh="true" data-trim-on-search="false" data-sort-name="pr.id" data-sort-order="desc" data-mobile-responsive="true" data-toolbar="" data-show-export="true" data-maintain-selected="true" data-query-params="payment_request_queryParams">
                        <thead>
                            <tr>
                                <th data-field="id" data-sortable="true">ID</th>
                                <th data-field="user_name" data-sortable="false">Username</th>
                                <th data-field="payment_type" data-sortable="true">Type</th>
                                <th data-field="payment_address" data-sortable="false">Payment Address</th>
                                <th data-field="amount_requested" data-sortable="false">Amount Requested</th>
                                <th data-field="remarks" data-sortable="false">Remarks</th>
                                <th data-field="status" data-sortable="false">Status</th>
                                <th data-field="date_created" data-sortable="false">Date Created</th>
                                <th data-field="operate" data-sortable="false">Actions</th>
                            </tr>
                        </thead>
                    </table>
                </div><!-- .card-innr -->
            </div><!-- .card -->
        </div>
</div>
<!-- /.row -->
</div><!-- /.container-fluid -->
</section>
<!-- /.content -->
</div>