<!-- <body class="hold-transition login-page"> -->
<div class="login-box container-fluid">
    <div class="authentication-wrapper authentication-cover">
        <div class="authentication-inner row">
            <!-- Left Text - Image -->
            <div class="d-none d-lg-flex col-lg-7 col-xl-8" style="background-color: #fff;">
                <div class="d-flex h-100" style="width: 100%;">
                    <!-- <a href="http://localhost/erestro-single/admin/login"> -->
                    <!-- <img src="https://img.freepik.com/free-photo/exploding-burger-with-vegetables-melted-cheese-black-background-generative-ai_157027-1734.jpg?w=1380&t=st=1689592536~exp=1689593136~hmac=716023812905494cfa6ee171bb05b28078dfedd26195feafb81987d13ab9eb44" class="img-fluid" alt="Login image" data-app-dark-img="illustrations/boy-with-rocket-dark.png" data-app-light-img="illustrations/boy-with-rocket-light.png"> -->
                    <img src="<?= BASE_URL() . $rider_cover_image ?>" class="img-fluid" alt="Login image" data-app-dark-img="illustrations/boy-with-rocket-dark.png" data-app-light-img="illustrations/boy-with-rocket-light.png">

                    <div class="dark-overlay"></div>
                    <!-- </a> -->
                </div>
            </div>
            <!-- Login Form -->
            <div class="d-flex col-12 col-lg-5 col-xl-4 align-items-center authentication-bg login-background-color">
                <div class="w-px-400 mx-auto">
                    <!-- ... Rest of the login form ... -->
                    <div class="w-px-400 mx-auto">
                        <?php if (ALLOW_MODIFICATION == 0) { ?>
                            <div class="alert alert-warning">
                                Note: If you cannot login here, please close the codecanyon frame by clicking on x Remove Frame button from top right corner on the page or <a href="<?= base_url('/admin') ?>" target="_blank" class="text-danger"> >> Click here << </a>
                            </div>
                        <?php } ?>

                        <div class="login-logo">
                            <a href="<?= base_url() . 'rider/login' ?>"><img src="<?= base_url() . $rider_logo ?>"></a>


                        </div>


                        <h4>
                            <p class="login-box-msg">Sign in to start your session</p>
                        </h4>

                        <form action="<?= base_url('rider/login/auth') ?>" class='form-submit-event' method="post">
                            <input type='hidden' name='<?= $this->security->get_csrf_token_name() ?>' value='<?= $this->security->get_csrf_hash() ?>'>
                            <div class="input-group mb-3">
                                <!-- <input type="<?= $identity_column ?>" class="form-control" name="identity" placeholder="<?= ucfirst($identity_column)  ?>" <?= (ALLOW_MODIFICATION == 0) ? 'value="9876543210"' : ""; ?>> -->
                                <input type="<?= $identity_column ?>" id="numberInput" oninput="validateNumberInput(this)" class="form-control" name="identity" placeholder="<?= ucfirst($identity_column)  ?>" <?= (ALLOW_MODIFICATION == 0) ? 'value="9987654321"' : 'value="9987654321"'; ?>>

                                <div class="input-group-append">
                                    <div class="input-group-text">
                                        <span class="fas <?= ($identity_column == 'email') ? 'fa-envelope' : 'fa-mobile' ?> "></span>
                                    </div>
                                </div>
                            </div>
                            <div class="input-group mb-3">
                                <!-- <input type="password" class="form-control" name="password" placeholder="Password" <?= (ALLOW_MODIFICATION == 0) ? 'value="12345678"' : ""; ?>> -->

                                <input type="password" class="form-control" name="password" placeholder="Password" <?= (ALLOW_MODIFICATION == 0) ? 'value="12345678"' : 'value="12345678"'; ?>>
                                <div class="input-group-append">
                                    <div class="input-group-text">
                                        <span class="fas fa-lock"></span>
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-8">
                                    <div class="icheck-info">
                                        <input type="checkbox" name="remember" id="remember">
                                        <label for="remember">
                                            Remember Me
                                        </label>
                                    </div>
                                </div>
                                <!-- /.col -->
                                <div class="col-12">
                                    <button type="submit" id="submit_btn" class="btn btn-block" style="background-color: #f0bb62;">Sign In</button>
                                </div>
                                <div class="mt-2 col-md-12 text-center">
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
</div>
<!-- ... Rest of the HTML ... -->








<!-- <?php if (ALLOW_MODIFICATION == 0) { ?>
    <div class="alert alert-warning">
        Note: If you cannot login here, please close the codecanyon frame by clicking on x Remove Frame button from top right corner on the page or <a href="<?= base_url('/admin') ?>" target="_blank" class="text-danger">>> Click here <<< /a>
    </div>
<?php } ?>
<div class="login-box">


    <div class="card container-fluid ">
        <div class="card-body login-card-body">
            <div class="login-logo">
                <a href="<?= base_url() . 'rider/login' ?>"><img src="<?= base_url() . $logo ?>"></a>
            </div>
            <p class="login-box-msg">Sign in to start your session</p>
            <form action="<?= base_url('rider/login/auth') ?>" class='form-submit-event' method="post">
                <div class="input-group mb-3">
                    <input type='hidden' name='<?= $this->security->get_csrf_token_name() ?>' value='<?= $this->security->get_csrf_hash() ?>'>
                    <input type="<?= $identity_column ?>" class="form-control" name="identity" placeholder="<?= ucfirst($identity_column)  ?>" <?= (ALLOW_MODIFICATION == 0) ? 'value="09537376387"' : 'value="09537376387"'; ?>>
                    <div class="input-group-append">
                        <div class="input-group-text">
                            <span class="fas <?= ($identity_column == 'email') ? 'fa-envelope' : 'fa-mobile' ?> "></span>
                        </div>
                    </div>
                </div>
                <div class="input-group mb-3">
                    <input type="password" class="form-control" name="password" placeholder="Password" <?= (ALLOW_MODIFICATION == 0) ? 'value="12345678"' : 'value="12345678"'; ?>>
                    <div class="input-group-append">
                        <div class="input-group-text">
                            <span class="fas fa-lock"></span>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-8">
                        <div class="icheck-info">
                            <input type="checkbox" name="remember" id="remember">
                            <label for="remember">
                                Remember Me
                            </label>
                        </div>
                    </div>
 
                    <div class="col-12">
                        <button type="submit" id="submit_btn" class="btn btn-info btn-block">Sign In</button>
                    </div>
                    <div class="justify-content-center mt-2 col-md-12">
                        <div class="form-group" id="error_box">
                        </div>
                    </div>
                </div>
            </form>
        </div>
     
    </div>
</div> -->