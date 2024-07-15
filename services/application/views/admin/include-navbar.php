<?php $current_version = get_current_version(); ?>
<!-- <nav class="main-header navbar navbar-expand navbar-dark navbar-info mt-2 mr-2" style="border-radius: 10px;padding-right: 20px;padding-left: 20px;"> -->
<nav class="main-header navbar navbar-expand navbar-dark navbar-info">
    <!-- Left navbar links -->
    <ul class="navbar-nav">
        <li class="nav-item">
            <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
        </li>
        <li class="nav-item my-auto">
            <span class="badge badge-light h5">v <?= (isset($current_version) && !empty($current_version)) ? $current_version : '1.0' ?></span>
        </li>
        <li class="nav-item my-auto ml-3">
            <a href="<?= base_url('admin/setting/system-status') ?>"><i class="fas fa-heartbeat fa-lg" style="color: #f0bb62;"></i></a>
        </li>
        <?php
        // print_r($_SESSION);

        ?>
        <!-- drop down start -->
        <ul class="navbar-nav navbar-right">
            <li class="dropdown d-inline">
                <!-- <div class="container ml-3"> -->
                <!-- <div class="dropdown"> -->
                <?php if (isset($_SESSION['branch_id'])) {
                    $selected_branch = fetch_details(['id' => $_SESSION['branch_id']], 'branch', '*');
                ?>
                    <a href="#" data-toggle="dropdown" class="nav-link dropdown-toggle nav-link-lg nav-link-user" id="dropdownMenuButton">
                        <div class="d-sm-none d-lg-inline-block"></div>
                        <!-- <button class="btn btn-primary dropdown-branch" type="button" id="dropdownMenuButton" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> -->
                        <?= isset($selected_branch[0]['branch_name']) ? $selected_branch[0]['branch_name'] : ''; ?>
                        <!-- </button> -->
                    </a>
                <?php } else { ?>
                    <!-- <button class="btn btn-primary dropdown-branch" type="button" id="dropdownMenuButton" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        Select Branch
                    </button> -->
                <?php }
                $branch = fetch_details("", 'branch', '*');
                ?>

                <div class="dropdown-menu" aria-labelledby="dropdownMenuButton">
                    <div class="dropdown-title text-center"><b>Branches</b></div>
                    <?php foreach ($branch as $key) { ?>
                        <a class="dropdown-item hover-pointer" data-id="<?= $key['id'] ?>">
                            <div class="product-image">
                                <img src="<?= isset($key['image']) ? base_url() . $key['image'] : '' ?>" alt="Branch Image" class="product-image">
                                <?= $key['branch_name'] ?>
                            </div>
                        </a>
                    <?php } ?>
                </div>
                <!-- </div> -->

                <!-- </div> -->
            </li>
        </ul>


        <!-- drop down end -->
        <?php
        if (defined('ALLOW_MODIFICATION') && ALLOW_MODIFICATION == 0) {
        ?>
            <li class="nav-item my-auto ml-2">
                <span class="badge badge-success">Demo mode</span>
            </li>
        <?php } ?>
    </ul>


    <!-- Right navbar links -->
    <ul class="navbar-nav ml-auto">

        <div id="google_translate_element"></div>

        <li class="nav-item">
            <a class="nav-link" id="panel_dark_mode" data-slide="true" href="#" role="button">
                <i id="dark-mode-icon" class="fas fa-moon" style="color: #f0bb62;"></i>
            </a>
        </li>
        <li class="nav-item dropdown">
            <a class="nav-link" data-toggle="dropdown" href="#">
                <i class="fa fa-user" style="color: #f0bb62;"></i>
            </a>
            <div class="dropdown-menu dropdown-menu-lg dropdown-menu-right">
                <?php if ($this->ion_auth->is_admin()) { ?>
                    <a href="#" class="dropdown-item">Welcome <b><?= ucfirst($this->ion_auth->user()->row()->username) ?> </b> ! </a>
                    <a href="<?= base_url('admin/home/profile') ?>" class="dropdown-item">
                        <i class="fas fa-user mr-2"></i> Profile
                    </a>
                    <a href="<?= base_url('admin/home/logout') ?>" class="dropdown-item">
                        <i class="fa fa-sign-out-alt mr-2"></i> Log Out
                    </a>
                <?php } else { ?>
                    <a href="#" class="dropdown-item">Welcome <b><?= ucfirst($this->ion_auth->user()->row()->username) ?> </b>! </a>
                    <a href="<?= base_url('rider/home/profile') ?>" class="dropdown-item"><i class="fas fa-user mr-2"></i> Profile </a>
                    <a href="<?= base_url('rider/home/logout') ?>" class="dropdown-item "><i class="fa fa-sign-out-alt mr-2"></i> Log Out </a>
                <?php } ?>
            </div>
        </li>
    </ul>
</nav>