
function myLucasKanade (im_template, im, mask)


im_template_mask_vec = im_template(mask);

% Initial warp
p = [0 0 0]';
delta_p = [99 99 99]';


% Compute pixel coordenates
[X_coord Y_coord] = meshgrid(1:size(im,2), 1:size(im,1));
X_coord_mask_vec = X_coord(mask);
Y_coord_mask_vec = Y_coord(mask);

% H_grad_x = [-1 0 1; -1 0 1; d-1 0 1];
H_grad_x = [-1 0 1];
H_grad_x = H_grad_x./norm(H_grad_x);
H_grad_y = H_grad_x';

% Compute gradient
im_grad_x = imfilter(im, H_grad_x);
im_grad_y = imfilter(im, H_grad_y);
    
delta_p_history = [];

while norm(delta_p) > 0.1
    
    % Step 1 apply warp
    im_warp = getTransformedImage(im, p);
    im_warp_mask_vec = im_warp(mask);
    
    % Step 2 compute error
    im_error_vec = im_template_mask_vec - im_warp_mask_vec;    
    
    % Step 3 warp gradient
    im_grad_x_warp = getTransformedImage(im_grad_x, p);
    im_grad_y_warp = getTransformedImage(im_grad_y, p);
    
    im_grad_x_warp_mask_vec = im_grad_x_warp(mask);
    im_grad_y_warp_mask_vec = im_grad_y_warp(mask);

    % Step 4 evaluate Jacovian
    % J = [-x*sin(p(1)) - y*cos(p(1)) 1 0;
    %      x*cos(p(1)) - y*sin(p(1)) 0 1];

    J(1,1,:) = -X_coord_mask_vec.*sin(p(1)) + Y_coord_mask_vec*cos(p(1));
    J(1,2,:) = 1;
    J(1,3,:) = 0;
    J(2,1,:) = -X_coord_mask_vec.*cos(p(1)) - Y_coord_mask_vec*sin(p(1));
    J(2,2,:) = 0;
    J(2,3,:) = 1;

    % Step 5 steepest image
    %arrayfun (@(ii) [im_grad_x_vec(ii), im_grad_y_vec(ii)] * J(:,:,ii), 1:3)
    steepest_descent_image = zeros(1,size(J,2), size(J,3));
    for i = 1:size(J,3)
        steepest_descent_image(:,:,i) = [im_grad_x_warp_mask_vec(i), im_grad_y_warp_mask_vec(i)] * J(:,:,i);
    end

    % imshow(mat2gray(reshape(steepest_descent_image(1,1,:), [256,256])))

    % Step 6 Compute hessian
    H = zeros(size(J,2));
    for i = 1:size(J,3)
%         H = H + J(:,:,i)'*J(:,:,i);
        H = H + steepest_descent_image(:,:,i)' * steepest_descent_image(:,:,i);
    end

    % Step 7
    % tic
%     sum_xy = zeros(size(steepest_descent_image,2),1);
%     for i = 1:size(J,3)
%         sum_xy = sum_xy + steepest_descent_image(:,:,i)' .* im_error_vec(i);
%     end
    % toc

    sum_xy = steepest_descent_image .* repmat(reshape(im_error_vec,1,1,[]), [1 size(steepest_descent_image,2)]);
    sum_xy = sum(sum_xy, 3)';

    % Step 8
    delta_p = -pinv(H) * sum_xy;
    
    % Step 9
    p = p + delta_p;
    
%     delta_p_history = [delta_p_history delta_p];
%     figure(1);
%     plot(delta_p_history(1,:));
%     hold on
%     plot(delta_p_history(2,:), 'r');
%     plot(delta_p_history(3,:), 'g');
%     hold off
%     
%     disp(['error: ' num2str(sum(im_error_vec.^2))]);
%     disp(p);
% %     disp(delta_p);
%     
%     figure(2);
% %     imshow([im_template_mask im_warp_mask]);
%     imshow(mat2gray(im_template-im_warp));
%     drawnow
end
end



function im_transformed = getTransformedImage (im, x)
            
alpha = x(1); % SE(2) Rotation
t1 = x(2); % SE(2) first dimension translation
t2 = x(3); % SE(2) second dimension translation
%             intencity_offset = x(4);

% Create SE(2) transform
tform = maketform('affine', ...
                    [cos(alpha) sin(alpha) t1; 
                     -sin(alpha) cos(alpha) t2;
                     0 0 1]'); 

% Apply transform on the image
%im_new_trans = imtransform(obj.im_new,tform);
im_transformed = imtransform(im, tform, ...
    'XData',[1 size(im,2)],...
    'YData',[1 size(im,1)]);
            
end