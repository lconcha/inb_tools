function h = plotGrad(grad, gradname)
% plotGrad(grad,gradname)

if nargin <2
   gradname='Gradient'; 
end


subplot(2,2,1)
plot(grad(:,1:3))
legend('x' ,'y' ,'z')
hold on
ylabel('Gradient amplitude')
title(gradname)


subplot(2,2,2)
try
    scatter3(grad(:,1), grad(:,2), grad(:,3), grad(:,4) ./ 100, grad(:,4), 'filled');
catch
    scatter3(grad(:,1), grad(:,2), grad(:,3), 50, grad(:,4), 'filled');
end
c = colorbar;
c.Label.String = 'b value';
hold on
plot3(grad(:,1), grad(:,2), grad(:,3),'- k')
set(gca,'XLim',[-1 1],'YLim',[-1 1],'ZLim',[-1 1])
xlabel('x')
ylabel('y')
zlabel('z')

subplot(2,2,3)
plot(grad(:,4),'-ok', 'Color',[0.5 0.5 0.5], 'MarkerFaceColor','k')
ylabel('b value')

subplot(2,2,4)
n = sqrt(grad(:,1).^2 + grad(:,2).^2 + grad(:,3).^2);
plot(n,'-ok', 'Color',[0.5 0.5 0.5], 'MarkerFaceColor','k');
ylabel('norm of gradient direction')

